#!/bin/bash
wait=1s

# 記事ページ一覧を引き抜き
pages=`wget -q http://aucfan.com/article/ -O - | grep -Po '(?<=<a href=")http:\/\/aucfan\.com\/article\/.*?\/(?=" class="box_link">)'`
echo 'URL一覧：'
echo -e "$pages"
echo
sleep $wait

# 記事をwget
IFS=$'\n' # 行単位で分割
for url in $pages; do
    echo "wget実行：$url"
    html=`wget -q $url -O -`

    title=`echo $html | grep -Po '(?<=<h1 class="entry-title">).*?(?=<\/h1>)'`
    date=`echo $html | grep -Po '(?<=<span class="sep">).*?(?=<\/span>)' | sed -Ee 's/[年月]/\//g' -e 's/日//g' -e 's/\/([0-9])\//\/0\1\//g'`
    content=`echo $html | grep -oP "(?<=<br class='wp_social_bookmarking_light_clear' \/>)[\s\S]*(?=<div class=\"social4i\" style=\"height:69px;\">)"`

    echo "url:$url"
    echo "title:$title"
    echo "date:$date"
    echo "content:"
    echo -e "$content"
    echo

    # LTSV形式で保存

    sleep $wait # 負荷軽減のため1秒sleep
done

# tsv変換→SQL実行
