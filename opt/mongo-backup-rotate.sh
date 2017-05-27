#!/usr/bin/env bash
#
# Backup:  $ docker exec rocketchatdocker_mongo_1 mongodump --archive=/dump/archive.json --gzip
# Restore: $ docker exec -it rocketchatdocker_mongo_1 mongorestore --archive=/dump/${TIMESTAMP}.json --gzip

DAYS_TO_KEEP="${DAYS_TO_KEEP:-6}"
MONGO_CONTAINER="${MONGO_CONTAINER:-rocketchatdocker_mongo_1}"
BACKUP_DIR="${BACKUP_DIR:-/opt/Rocket.Chat-docker/data/backup}"
TIMESTAMP="$(date +%Y%m%d%H%M)"

# Write dump
eval "docker exec ${MONGO_CONTAINER} mongodump --archive=/dump/${TIMESTAMP}.json --gzip"

# Rotate/delete old backups
if [[ -d "${BACKUP_DIR}" ]]; then
  printf "Rotating logs… "
  find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.json" -mtime +${DAYS_TO_KEEP} -exec rm -f {} \; && echo done
fi
