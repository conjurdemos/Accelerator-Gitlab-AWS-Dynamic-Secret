#!/usr/bin/env bash

source local.env

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_issuer-ephemerals.htm

# NOTE: You need Conjur Cloud admin permissions to create a Conjur Cloud issuer resource.

CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)

ISSUER_ID="${1}"
MAX_TTL=${2:-900}

if [ -z "$ISSUER_ID" ] || [ -z "$MAX_TTL" ]; then
    echo "Usage: $0 <ISSUER_ID> <MAX_TTL>"
    exit 1
fi

export ACCESS_KEY="$NEW_AWS_ACCESS_KEY_ID"
export SECRET_KEY="$NEW_AWS_SECRET_ACCESS_KEY"
if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
    echo "Set NEW_AWS_ACCESS_KEY_ID and NEW_AWS_SECRET_ACCESS_KEY in the environment"
    echo "then run this script again"
    exit 2
fi
if [ -z "$CONJ_URL" ]; then
    echo "Set CONJ_URL in the environment"
    echo "then run this script again"
    exit 3
fi

BODY_JSON=$(jq -c -n --arg ID $ISSUER_ID --arg TTL $MAX_TTL --arg KEY $ACCESS_KEY --arg SECRET $SECRET_KEY '{"id":$ID,"max_ttl":900,"type":"aws","data":{"access_key_id":$KEY,"secret_access_key":$SECRET}}')

# POST /api/issuers/conjur
URL="$CONJ_URL/api/issuers/conjur"
curl -s -D - -XPOST $URL \
     -H "content-type: application/json; charset=utf-8" \
     -H "Authorization: Token token=\"$CONJ_TOKEN\"" \
     -d "$BODY_JSON"
