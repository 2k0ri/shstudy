#!/bin/bash
baseurl='http://aucfan.com/article/'
articlebase=$baseurl
wait=0.2s

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

    slug=`echo $url | sed -Ee 's/.*\/(.*)\/$/\1/g'`
    title=`echo $html | grep -Po '(?<=<h1 class="entry-title">).*?(?=<\/h1>)'`
    date=`echo $html | grep -Po '(?<=<span class="sep">).*?(?=<\/span>)' | sed -Ee 's/[年月]/\//g' -e 's/日//g' -e 's/\/([0-9])\//\/0\1\//g'`
    content=`echo $html | grep -Po "(?<=<br class='wp_social_bookmarking_light_clear' \/>)[\s\S]*(?=<div class=\"social4i\" style=\"height:69px;\">)" | tr -d '\n' | tr -d '\r'`

    echo "slug:$slug"
    echo "url:$url"
    echo "title:$title"
    echo "date:$date"
    echo

    # LTSV形式で保存
    echo -e "url:$url\ttitle:$title\tdate:$date\tcontent:$content" >> contents.ltsv

    sleep $wait # 負荷軽減のためsleep
done

# tsv変換→SQL実行
