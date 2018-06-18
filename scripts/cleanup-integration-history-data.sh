#!/usr/bin/env bash
# Script to remove integration history data in Rocket.Chat's MongoDB database.
#
# Env vars:
#   - DELETE_OLDER_THAN_DAYS (defaults to 5)
#
# Written by: Jonas "frdmn" Friedmann <j@frd.mn>
# Requirements: mongo (cli), docker-compose
# Licensed under MIT

export PATH="/usr/local/bin:/usr/bin:/bin"

echod() {
    printf "[`date`] $1\n"
}

TIMER_START=$(date +%s)
COMPOSE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

DELETE_OLDER_THAN_DAYS=${DELETE_OLDER_THAN_DAYS:-5}

if [[ "$OSTYPE" == "darwin"* ]]; then
    DATE_STAMP=$(date -v-${DELETE_OLDER_THAN_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")
elif [[ "$OSTYPE" == "linux"* ]]; then
    DATE_STAMP=$(date -d "now - ${DELETE_OLDER_THAN_DAYS} day" +"%Y-%m-%dT%H:%M:%SZ")
else
    echod "Error: not supported operating system"
    exit 1
fi

MONGO_QUERY="""
db.rocketchat_integration_history.remove({ 
	"_createdAt": { \"\$lt\": ISODate(\"${DATE_STAMP}\") }
})
"""

echod "$(docker-compose -f ${COMPOSE_DIR}/docker-compose.yml run --rm mongo mongo "mongo/rocketchat" --quiet --eval "${MONGO_QUERY}")"

TIMER_END=$(date +%s)
TIMER_RUNTIME=$((TIMER_END-TIMER_START))
echo "Runtime: ${TIMER_RUNTIME} seconds"
exit 0