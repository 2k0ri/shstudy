#!/bin/bash
readonly IS_USE_LTSV=0 # 0でLTSV、それ以外でTSV
readonly CACHE_DIR='cache/' # キャッシュ保存フォルダ(/で終了)
WAIT=0.1s
readonly BASEURL='http://aucfan.com/article/'

# 拡張子を判別
ext='ltsv'
[ ! "${IS_USE_LTSV}" -eq 0 ] && export ext='tsv'
echo "${ext}形式で保存..."
echo

# キャッシュフォルダがなければ作成
[ ! -e ${CACHE_DIR} ] && mkdir -p ${CACHE_DIR}

# 記事ページ一覧を引き抜き
INDEX=`wget -q http://aucfan.com/article/ -O - | grep -Po "(?<=<a class\=\'page-number num\' href\=\'http:\/\/aucfan\.com\/article\/\?paged=)\d+(?='>\d+<\/a>)" | tail -n 1`
echo 'URL一覧：'
for (( i = 1; i <= ${INDEX}; i++ )); do
    echo "URL一覧取得 ${i}/${INDEX}..."
    PAGES=`wget -q http://aucfan.com/article/?paged=$i -O - | grep -Po '(?<=<a href=")http:\/\/aucfan\.com\/article\/.*?\/(?=" class="box_link">)'`
    echo -e "${PAGES}"
    echo
    sleep "${WAIT}"

    # 記事をwget
    IFS=$'\n' # 行単位で分割
    for URL in $PAGES; do
        slug=`echo "${URL}" | grep -Po '[^\/]*(?=\/$)'`

        # キャッシュ有無の判定
        CACHE_FILE=`ls "${CACHE_DIR}" | grep "${slug}"`
        IS_EXIST_CACHE=`[ -f "${CACHE_DIR}${CACHE_FILE}" ]`

        if [ -f "${CACHE_DIR}${CACHE_FILE}" ]; then
            echo "キャッシュから読み込み：${slug}"
            HTML=`cat "${CACHE_DIR}${CACHE_FILE}"`
        else
            echo "wget実行：${URL}"
            HTML=`wget -q "${URL}" -O -`
        fi

        date=`echo "${HTML}" | grep -Po '(?<=<span class="sep">).*?(?=<\/span>)' | sed -Ee 's/[年月]/\//g' -e 's/日//g' | xargs date +%Y%m%d -d`
        title=`echo "${HTML}" | grep -Po '(?<=<h1 class="entry-title">).*?(?=<\/h1>)'`
        content=`echo "${HTML}" | tr -d '\n' | tr -d '\r' | tr -d '\t' | grep -Po "(?<=<br class='wp_social_bookmarking_light_clear' \/>).*(?=<div class=\"social4i\" style=\"height:69px;\">)"`

        # ファイル保存
        if [ ! -f "${CACHE_DIR}${CACHE_FILE}" ]; then
            # キャッシュファイル名のフォーマット
            CACHE_FILE_FORMAT="${date}_${slug}.html"
            echo ${HTML} > "${CACHE_DIR}${CACHE_FILE_FORMAT}"
        fi

        for arg in date slug title; do
            echo "${arg}:${!arg}"
        done
        echo

        # ファイル保存
        record=()
        # IFS=$'\s'
        for arg in date slug title content; do
            if [ "${IS_USE_LTSV}" -eq 0 ]
            then
                record[${#record[@]}]="${arg}:${!arg}"
            else
                record[${#record[@]}]="${!arg}"
            fi
        done

        # タブ区切りで結合して保存
        IFS=$'\t'
        echo "${record[*]}" >> contents."${ext}"

        sleep "${WAIT}" # 負荷軽減のためsleep
    done
done

echo "URL取得完了"
echo

# tsv変換→SQL実行
