#!/usr/bin/env bash

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/conjurcloud/apis/ccl-api-del-auth.htm

# You must have Conjur Cloud admin permissions to allowlist authenticator endpoints.

source local.env

# Ex: authn-jwt/example-authenticator
AUTHENTICATOR="${1}"

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The authorization token must have create permissions for the policy specified in the request URL.
CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)

# DELETE https://<subdomain>.secretsmgr.cyberark.cloud/api/authenticators/<type>/<name>
# DELETE /api/authenticators/authn-jwt/github
# Authorization: Token token="eyJ..."
# Accept: application/x.secretsmgr.v2+json
# Host: acme.secretsmgr.cyberark.cloud
QP_AUTHN=$(echo -n "$AUTHENTICATOR" | jq -sRr @uri)
URL="$CONJ_URL/api/authenticators/${QP_AUTHN}"
curl -s $CURL_OPTS -XDELETE $URL \
     -H "Authorization: Token token=\"$CONJ_TOKEN\"" \
     -H "Accept: application/x.secretsmgr.v2+json"
