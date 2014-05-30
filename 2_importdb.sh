#!/bin/bash

# 設定読み込み
. ${PWD}/config.sh

tsvfile="${PWD}/${RECORD_FILE}.tsv"

# LTSVモードの時はTSVに変換
if [ "${IS_USE_LTSV}" -eq 0 ]; then
    echo "TSVに変換します"
    sed -Ee 's/(date|slug|title|content)://g' ${RECORD_FILE}.ltsv > ${PWD}/_tmp.tsv
    tsvfile="${PWD}/_tmp.tsv"
fi

# tsvを流し込み
mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASS}" -A "${MYSQL_DBNAME}" -e "LOAD DATA LOCAL INFILE '${tsvfile}' INTO TABLE shstudy_auc_topics(date, slug, title, content)"

[[ $? ]] && echo "データベースインポート完了"
[ "${IS_USE_LTSV}" -eq 0 ] && rm ${tsvfile}

