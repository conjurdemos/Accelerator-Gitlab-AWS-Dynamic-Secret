#!/usr/bin/env bash

# 

# You must have Conjur Cloud admin permissions to allowlist authenticator endpoints.

source local.env

# Ex: authn-jwt/example-authenticator
AUTHENTICATOR="${1}"

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# The authorization token must have create permissions for the policy specified in the request URL.
CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)


# PATCH https://<subdomain>.secretsmgr.cyberark.cloud/api/{authenticator-type}/{service-id}/conjur

# curl --location --request PATCH 'https://<subdomain>.secretsmgr.cyberark.cloud/api/authn-iam/prod/conjur' \
# --header 'Authorization: Token token="eyJwc....."' \
# --header 'Content-Type: text/plain' \
# --data-raw 'enabled=true'

#2025-04-18 11:31:13,205 DEBUG: Invoke endpoint succeeded. Duration: 858ms, Request: 
#PATCH https://cybr-secrets.secretsmgr.cyberark.cloud/api/authn-jwt%2Fdh-glab62e-authn/conjur,
# Response: {'status': 204, 'content length': '0'}
QP_AUTHN=$(echo -n "$AUTHENTICATOR" | jq -sRr @uri)
URL="$CONJ_URL/api/${QP_AUTHN}/conjur"
curl -s $CURL_OPTS -XPATCH $URL \
     -H "Authorization: Token token=\"$CONJ_TOKEN\"" \
     -H "Content-Type: text/plain" \
     --data-raw "enabled=true"
