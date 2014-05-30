#!/bin/bash

# 設定パラメータ
readonly IS_USE_LTSV=0 # 0でLTSV、それ以外でTSV
readonly IS_INITIALIZE=1 # 0で差分のみ取得、それ以外で全取得
readonly CACHE_DIR='cache/' # キャッシュ保存フォルダ(/で終了)
readonly WAIT=0.1s


# 拡張子を判別
ext='ltsv'
[ ! "${IS_USE_LTSV}" -eq 0 ] && export ext='tsv'
echo "${ext}形式で保存..."
echo

# キャッシュフォルダがなければ作成
[ ! -e ${CACHE_DIR} ] && mkdir -p ${CACHE_DIR}

# 記事ページ一覧を引き抜き
INDEX=`curl -s -o - http://aucfan.com/article/ | grep -Po "(?<=<a class\=\'page-number num\' href\=\'http:\/\/aucfan\.com\/article\/\?paged=)\d+(?='>\d+<\/a>)" | tail -n 1`
echo 'URL一覧：'
for (( i = 1; i <= ${INDEX}; i++ )); do
    echo "URL一覧取得 ${i}/${INDEX}..."
    PAGES=`curl -s -o - http://aucfan.com/article/?paged=$i | grep -Po '(?<=<a href=")http:\/\/aucfan\.com\/article\/.*?\/(?=" class="box_link">)'`
    echo -e "${PAGES}"
    echo

    # 記事をcurl
    IFS=$'\n' # 行単位で分割
    for URL in $PAGES; do
        slug=`echo "${URL}" | grep -Po '[^\/]*(?=\/$)'`

        # キャッシュ有無の判定
        CACHE_FILE=`ls "${CACHE_DIR}" | grep "${slug}"`
        IS_EXIST_CACHE=`[ -f "${CACHE_DIR}${CACHE_FILE}" ]`

        WGET_COUNT=0
        if [ -f "${CACHE_DIR}${CACHE_FILE}" ]; then
            echo "キャッシュから読み込み：${slug}"
            HTML=`cat "${CACHE_DIR}${CACHE_FILE}"`
        else
            WGET_COUNT+=1
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
            if [ "${IS_USE_LTSV}" -eq 0 ]
            then
                record[${#record[@]}]="${arg}:${!arg}"
            else
                record[${#record[@]}]="${!arg}"
            fi
        done
        IFS=$'\t' # タブ区切りで結合して保存
        echo "${record[*]}" >> contents."${ext}"

        # HTML保存
        if [ ! -f "${CACHE_DIR}${CACHE_FILE}" ]; then
            CACHE_FILE_FORMAT="${date}_${slug}.html" # キャッシュファイル名のフォーマット
            echo ${HTML} > "${CACHE_DIR}${CACHE_FILE_FORMAT}"
        fi

        for arg in date slug title; do
            printf "${arg}:${!arg}\t"
        done
        echo $'\n'
    done
    # １ページすべてキャッシュ済だった場合はクロールを中断、更新完了
    if [ "${IS_INITIALIZE}" -eq 0 ] && [[ "${WGET_COUNT}" -eq 0 ]]; then
        echo
        echo "更新完了"
        echo
        break
    fi
done
echo "URL取得完了"
