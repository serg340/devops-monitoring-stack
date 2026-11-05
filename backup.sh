#!/usr/bin/env bash
set -Eeuo pipefail

DATE="$(date +%F-%H-%M)"
DATABASE="${BACKUP_DATABASE:-sto_prod}"
FILE="${DATABASE}_${DATE}.sql"

cleanup() {
  rm -f "$FILE"
}
trap cleanup EXIT

docker exec mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqldump --single-transaction --routines --triggers -uroot "$1"' sh "$DATABASE" > "$FILE"

test -s "$FILE"
mc cp "$FILE" "local/mysql-backups/"
echo "Backup uploaded: local/mysql-backups/$FILE"
