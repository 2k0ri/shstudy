#!/bin/bash

# 設定読み込み
. $(dirname $0)/config.sh

# 拡張子を判別
ext='ltsv'
[ ! "${IS_USE_LTSV}" -eq 0 ] && export ext='tsv'
echo "${ext}形式で保存..."
echo

# キャッシュフォルダがなければ作成
[ ! -e $(dirname $0)/${CACHE_DIR} ] && mkdir -p 

# 記事ページ一覧を引き抜き
INDEX=`curl -s -o - http://aucfan.com/article/ | grep -Po "(?<=<a class\=\'page-number num\' href\=\'http:\/\/aucfan\.com\/article\/\?paged=)\d+(?='>\d+<\/a>)" | tail -n 1`

# URL一覧をフェッチ→個別記事取得のループ
for (( i = 1; i <= ${INDEX}; i++ )); do
    if [[ -n "${URL_FETCH_COUNT}" ]] && [ "${URL_FETCH_COUNT}" -eq 0 ]; then
        echo "URL一覧をキャッシュから取得"
        PAGES=`cat $(dirname $0)/${CACHE_DIR}${URL_LIST}`
        i=${INDEX}
    else
        echo "URL一覧取得 ${i}/${INDEX}..."
        PAGES=`curl -s -o - http://aucfan.com/article/?paged=$i | grep -Po '(?<=<a href=")http:\/\/aucfan\.com\/article\/.*?\/(?=" class="box_link">)'`
        URL_FETCH_COUNT=0 # このページから新たに取得した記事数、0の場合はクロールを停止してキャッシュのリストを代入
    fi
    echo -e "${PAGES}"
    echo

    # 記事をcurl
    IFS=$'\n' # 行単位で分割
    for URL in $PAGES; do
        slug=`echo "${URL}" | grep -Po '[^\/]*(?=\/$)'`

        # URL一覧にない場合はカウントアップして登録
        if [[ -z `grep "${URL}" "$(dirname $0)/${CACHE_DIR}${URL_LIST}"` ]]; then
            echo "${URL}" >> "$(dirname $0)/${CACHE_DIR}${URL_LIST}"
            URL_FETCH_COUNT+=1
        fi

        # レコード登録済の場合は次のURLへ
        if [[ -n `grep "${slug}" "$(dirname $0)/${RECORD_FILE}.${ext}"` ]]; then
            echo "保存済み：${slug}"
            continue
        fi
        # キャッシュ有無の判定
        CACHE_FILE=`ls "$(dirname $0)/${CACHE_DIR}" | grep "${slug}"`

        CURL_COUNT=0
        if [ -f "$(dirname $0)/${CACHE_DIR}${CACHE_FILE}" ]; then
            echo "キャッシュから読み込み：${slug}"
            HTML=`cat "$(dirname $0)/${CACHE_DIR}${CACHE_FILE}"`
        else
            CURL_COUNT+=1
            echo "curl実行 ${URL} ..."
            sleep "${WAIT}"
            HTML=`curl -s -o - "${URL}"`
        fi

        # パラメータの切り出し
        date=`echo "${HTML}" | grep -Po '(?<=<span class="sep">).*?(?=<\/span>)' | sed -Ee 's/[年月]/\//g' -e 's/日//g' | xargs date +%Y%m%d -d`
        title=`echo "${HTML}" | grep -Po '(?<=<h1 class="entry-title">).*?(?=<\/h1>)'`
        content=`echo "${HTML}" | tr -d '\n' | tr -d '\r' | tr -d '\t' | grep -Po "(?<=<br class='wp_social_bookmarking_light_clear' \/>).*(?=<div class=\"social4i\" style=\"height:69px;\">)"`

        # *tsvファイルにレコードを書き込み
        record=()
        for arg in date slug title content; do
            if [ "${IS_USE_LTSV}" -eq 0 ]; then
                record[${#record[@]}]="${arg}:${!arg}"
            else
                record[${#record[@]}]="${!arg}"
            fi
        done
        IFS=$'\t' # タブ区切りで結合して保存
        echo "${record[*]}" >> "$(dirname $0)/${RECORD_FILE}"."${ext}"

        # HTML保存
        if [ ! -f "$(dirname $0)/${CACHE_DIR}${CACHE_FILE}" ]; then
            CACHE_FILE_FORMAT="${date}_${slug}.html" # キャッシュファイル名のフォーマット
            echo ${HTML} > "$(dirname $0)/${CACHE_DIR}${CACHE_FILE_FORMAT}"
        fi

        for arg in date slug title; do
            printf "${arg}:${!arg}\t"
        done
        echo $'\n'
    done
    # １ページすべてキャッシュ済だった場合はクロールを中断、更新完了
    if [ "${IS_INITIALIZE}" -eq 0 ] && [[ "${CURL_COUNT}" -eq 0 ]]; then
        echo
        echo "更新完了"
        echo
        break
    fi
done
echo
echo "${RECORD_FILE}.${ext}に保存しました"

# DBへインポート
echo "データベースにインポート..."
$(dirname $0)/2_importdb.sh

