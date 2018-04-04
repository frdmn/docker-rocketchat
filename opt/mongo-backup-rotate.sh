#!/usr/bin/env bash
#
# Backup:  $ docker-compose run mongo mongodump -h mongo --archive=/dump/201804050001
# Restore: $ docker-compose run mongo mongorestore -h mongo --archive=/dump/201804050001 --gzip

CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DAYS_TO_KEEP:=6}
${MONGO_CONTAINER:=mongo}
${BACKUP_DIR:=$CURRENTDIR/../data/backups}
TIMESTAMP="$(date +%Y%m%d%H%M)"

# Write dump
eval "docker-compose run ${MONGO_CONTAINER} mongodump -h mongo --archive=/dump/${TIMESTAMP}.json ${GZIP}"

# Rotate/delete old backups
if [[ -d "${BACKUP_DIR}" ]]; then
  printf "Rotating logs... "
  find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*.json" -mtime +${DAYS_TO_KEEP} -exec rm -f {} \; && echo done
fi
