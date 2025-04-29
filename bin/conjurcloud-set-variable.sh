#!/usr/bin/env bash

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_append_policy.htm
# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_set_secret.htm

source local.env

if [[ -z "${1}" || -z "${2}" ]]; then
  echo "Usage: $0 <variable> <value>"
  exit 1
fi

VARIABLE="${1}"
VALUE="${2}"

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The authorization token must have create permissions for the policy specified in the request URL.
CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)

# POST /api/secrets/conjur/{kind}/{identifier}
# Authorization: Token token="<token>"

# curl -H 'Authorization: Token token="<the token>"' \
#     --data "c3c60d3f266074" \
#     https://<subdomain>.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fprod%2Fdb%2Fpassword

QP_VAR=$(echo -n "$VARIABLE" | jq -sRr @uri)
URL="$CONJ_URL/api/secrets/conjur/variable/${QP_VAR}"
curl -s $CURL_OPTS -XPOST $URL \
     -H "Authorization: Token token=\"$CONJ_TOKEN\"" \
     --data "$VALUE"
