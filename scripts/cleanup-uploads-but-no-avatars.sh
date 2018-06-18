#!/usr/bin/env bash
# Script to remove old uploads in Rocket.Chat instances for people using the filesystem storage method.
# This script makes sure to NOT remove users avatars. Because they are stored in the same directory we
# have to query the Mongo to check if a file is a regular file upload or a avatar.
#
# Env vars:
#   - DELETE_OLDER_THAN_DAYS (defaults to 5)
#
# Written by: Jonas "frdmn" Friedmann <j@frd.mn>
# Requirements: mongo (cli), docker-compose, jq, tofrodos package
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
db.rocketchat_uploads.find({
    \$and: [
        { uploadedAt: { \"\$lt\": ISODate(\"${DATE_STAMP}\") } },
        { store: \"FileSystem:Uploads\" }
    ]
}, {
    \"_id\":1,
    \"extension\":1,
}).toArray()
"""

RESULT_ARRAY=$(docker-compose -f ${COMPOSE_DIR}/docker-compose.yml run --rm mongo mongo "mongo/rocketchat" --quiet --eval "${MONGO_QUERY}" | todos |    jq -r '.[] | ._id + "." + .extension') # pass to "todos" because jq expects windows line breaks???

if [[ ${#RESULT_ARRAY} < 1 ]]; then
    echod "Info: no uploads found"
    exit 0
fi

RESULT_COUNT=$(echo "${RESULT_ARRAY}" | wc -l | xargs) # xargs to trim whitespaces

echod "Found ${RESULT_COUNT} entry/entries..."

if [[ -n "${RESULT_ARRAY}" ]]; then
    while read -r RESULT; do
        UPLOAD_ID=${RESULT%.*}
        UPLOAD_EXTENSION=${RESULT##*.}
        MONGO_REMOVE_QUERY="db.rocketchat_uploads.remove({_id:\"${UPLOAD_ID}\"})"

        MONGO_REMOVE_OUTPUT=$(docker-compose -f ${COMPOSE_DIR}/docker-compose.yml run --rm mongo mongo "mongo/rocketchat" --quiet --eval "${MONGO_REMOVE_QUERY}" </dev/null)
        MONGO_REMOVE_RETURNCODE=$?

        if [[ ${MONGO_REMOVE_RETURNCODE} == 0 ]]; then
            echod "Successfully removed upload \"${UPLOAD_ID}\" from MongoDB"
            rm -v "${COMPOSE_DIR}/data/uploads/${UPLOAD_ID}"* &> /dev/null
            RM_REMOVE_RETURNCODE=$?
            if [[ ${RM_REMOVE_RETURNCODE} == 0 ]]; then
                echod "Successfully removed upload \"${UPLOAD_ID}\" from FileSystem"
            else
                echod "Failed to remove upload \"${UPLOAD_ID}\" from FileSystem"
            fi
        else
            echod "Failed to remove upload \"${UPLOAD_ID}\" from MongoDB"
        fi
    done <<< "${RESULT_ARRAY}"
fi

TIMER_END=$(date +%s)
TIMER_RUNTIME=$((TIMER_END-TIMER_START))
echo "Runtime: ${TIMER_RUNTIME} seconds"
exit 0