#!/usr/bin/env bash

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_append_policy.htm

source local.env

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IDENTIFIER="$1"
POLICY_FILE="$2"

# Check if IDENTIFIER and POLICY_FILE are provided
if [[ -z "$IDENTIFIER" || -z "$POLICY_FILE" ]]; then
  echo "Usage: $0 <identifier> <policy_file>"
  exit 1
fi

if ! [ -f "$POLICY_FILE" ]; then
  echo "Error: parameter policy_file is not a file."
  echo "Usage: $0 <identifier> <policy_file>"
  exit 1
fi

cat "$POLICY_FILE"

# The authorization token must have create permissions for the policy specified in the request URL.
CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)

# PUT  /api/policies/conjur/policy/<identifier>  #REPLACE
# POST /api/policies/conjur/policy/<identifier>  #UPDATE
# Authorization: Token token="<token>"
# Content-Type: text/plain

QP_IDENTIFIER=$(echo -n "$IDENTIFIER" | jq -sRr @uri)

#POLICIES = "{url}/policies/{account}/policy/{identifier}"
URL="$CONJ_URL/api/policies/conjur/policy/${QP_IDENTIFIER}"
curl -s $CURL_OPTS -XPOST $URL \
     -H "Authorization: Token token=\"$CONJ_TOKEN\"" \
     -H "Content-Type: text/plain" \
     --data-binary @${POLICY_FILE}
