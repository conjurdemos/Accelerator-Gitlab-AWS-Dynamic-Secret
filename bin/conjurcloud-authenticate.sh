#!/usr/bin/env bash

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IDTOKEN=$(bash $SCRIPT_DIR/idclient-authenticate.sh)

# POST /api/authn-oidc/cyberark/conjur/authenticate
# Accept-Encoding: base64
# Content-Type: application/x-www-form-urlencoded
# id_token=eyJhbGciOi...

CONJUR_URL="$CONJ_URL/api/authn-oidc/cyberark/conjur/authenticate"

curl -s -XPOST $CONJUR_URL \
-H 'Accept-Encoding: base64' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-d "id_token=$IDTOKEN"