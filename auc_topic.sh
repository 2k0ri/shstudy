#!/bin/bash
wait=1s

# 記事ページ一覧を引き抜き
pages=`wget -q http://aucfan.com/article/ -O - | grep -Po '(?<=<a href=")http://.*/(?=" class="box_link">)'`
echo 'URL一覧：'
echo $pages
sleep $wait

# 記事をwget
echo
echo 'wget実行...'
IFS=$'\n' # 行単位で分割
for url in $pages; do
    echo "wget実行：$url"
    html=`wget -q $url -O -`
# echo $html

    # LTSV形式で保存

    # 負荷軽減のため１秒sleep
    sleep $wait
done

# tsv変換→SQL実行
