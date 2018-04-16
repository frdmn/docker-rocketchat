#!/usr/bin/env bash
MONGO_CONTAINER=${MONGO_CONTAINER:-"mongo"}
TIMESTAMP="$(date +%Y%m%d%H%M)"

if [[ -n "${GZIP}" ]]; then
	GZIP=" --gzip"
fi

eval "docker-compose run --rm ${MONGO_CONTAINER} mongodump -h mongo --archive=/dump/${TIMESTAMP}.json${GZIP}"

exit 0