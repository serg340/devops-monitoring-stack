#!/usr/bin/env bash
set -Eeuo pipefail

# Creates a local SQL dump and uploads it to the configured MinIO alias/bucket.
# The MySQL container must have MYSQL_ROOT_PASSWORD set in its environment.
# Configure the MinIO client alias separately with: mc alias set ...

BACKUP_DIR="${BACKUP_DIR:-./backups}"
BUCKET_PATH="${BACKUP_BUCKET_PATH:-local/mysql-backups}"
DATABASE="${BACKUP_DATABASE:-sto_prod}"
TIMESTAMP="$(date +%F-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${DATABASE}_${TIMESTAMP}.sql"

umask 077
mkdir -p "$BACKUP_DIR"

cleanup() {
  rm -f "$BACKUP_FILE"
}
trap cleanup EXIT

docker exec mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysqldump --single-transaction --routines --triggers -uroot "$1"' sh "$DATABASE" > "$BACKUP_FILE"

test -s "$BACKUP_FILE"
mc cp "$BACKUP_FILE" "$BUCKET_PATH/"

echo "Backup uploaded: $BUCKET_PATH/$(basename "$BACKUP_FILE")"
