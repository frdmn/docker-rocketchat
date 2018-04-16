#!/usr/bin/env bash
MONGO_CONTAINER=${MONGO_CONTAINER:-"mongo"}

if [[ -z "${IMPORTFILE}" ]]; then
	echo "Error: No IMPORTFILE environment variable found."
	exit 1
fi

if [[ "${GZIP}" == "true" ]]; then
	GZIP=" --gzip"
fi

eval "docker-compose run --rm ${MONGO_CONTAINER} mongorestore -h mongo --drop --archive=/dump/${IMPORTFILE}${GZIP}"

exit 0