#!/bin/bash

# 設定パラメータ
readonly IS_USE_LTSV=0 # 0でLTSV、それ以外でTSV
readonly IS_INITIALIZE=1 # 0で差分のみ取得、それ以外で全取得
readonly CACHE_DIR='cache/' # キャッシュ保存フォルダ(/で終了)
readonly RECORD_FILE='contents' # レコード保存ファイル名(拡張子なし)
readonly URL_LIST='urllist.txt' # URLリスト保存ファイル名(拡張子つき)
readonly WAIT=0.1s

# データベース設定
readonly MYSQL_HOST='127.0.0.1'
readonly MYSQL_USER='shstudy'
readonly MYSQL_PASS='shstudy'
readonly MYSQL_DBNAME='shstudy'
