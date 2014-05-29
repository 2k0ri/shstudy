#!/bin/bash
readonly BASEURL='http://aucfan.com/article/'
readonly IS_USE_LTSV=1 # 0でLTSV、それ以外でTSV
wait=0.1s

# 拡張子を判別
ext='ltsv'
[ ! "${IS_USE_LTSV}" -eq 0 ] && export ext='tsv'
echo "${ext}形式で保存..."
echo

# 記事ページ一覧を引き抜き
pages=`wget -q http://aucfan.com/article/ -O - | grep -Po '(?<=<a href=")http:\/\/aucfan\.com\/article\/.*?\/(?=" class="box_link">)'`
echo 'URL一覧：'
echo -e "${pages}"
echo
sleep "${wait}"

# 記事をwget
for url in $pages
do
    IFS=$'\n' # 行単位で分割
    echo "wget実行：${url}"
    IFS=${IFS_ORG}
    html=`wget -q $url -O -`

    date=`echo "${html}" | grep -Po '(?<=<span class="sep">).*?(?=<\/span>)' | sed -Ee 's/[年月]/\//g' -e 's/日//g' | xargs date +%Y/%m/%d -d`
    slug=`echo "${url}" | sed -Ee 's/.*\/([-_0-9a-zA-Z]*)\/$/\1/'`
    title=`echo "${html}" | grep -Po '(?<=<h1 class="entry-title">).*?(?=<\/h1>)'`
    content=`echo "${html}" | tr -d '\n' | tr -d '\r' | tr -d '\t' | grep -Po "(?<=<br class='wp_social_bookmarking_light_clear' \/>).*(?=<div class=\"social4i\" style=\"height:69px;\">)"`

    for arg in date slug title
    do
        echo "${arg}:${!arg}"
    done
    echo

    # ファイル保存
    record=()
    # IFS=$'\s'
    for arg in date slug title content
    do
        if [ "${IS_USE_LTSV}" -eq 0 ]
        then
            record[${#record[@]}]="${arg}:${!arg}"
        else
            record[${#record[@]}]="${!arg}"
        fi
    done
    IFS=$'\t'
    echo "${record[*]}" >> contents."${ext}"

    sleep "${wait}" # 負荷軽減のためsleep
done

# tsv変換→SQL実行
