#!/usr/bin/env bash
# Use this script when your backup is a directory from dump like: mongodump --out directory
MONGO_CONTAINER=${MONGO_CONTAINER:-"mongo"}

if [[ -z "${IMPORTFILE}" ]]; then
	echo "Error: No IMPORTFILE environment variable found."
	exit 1
fi

if [[ "${GZIP}" == "true" ]]; then
	GZIP=" --gzip"
fi

eval "docker-compose run --rm ${MONGO_CONTAINER} mongorestore -h mongo --drop /dump/${IMPORTFILE}${GZIP}"

exit 0
