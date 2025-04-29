#!/usr/bin/env bash

export IDTENANTURL
export IDUSER
export IDPASS

if [ -z "$IDTENANTURL" ]; then
    echo "Set IDTENANTURL, IDUSER, IDPASS and try again."
    exit 1
fi

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_authenticate_user.htm

# Start Authentication
# POST /Security/StartAuthentication
# Content-Type: application/json
# {
#   "Version": "1.0",
#   "User": "jdoe@acme.com"
# }
BODY_JSON=$(jq -n --arg User $IDUSER  '{Version: "1.0"} + $ARGS.named' )
START=$(curl -s -XPOST -H 'Content-Type: application/json' "$IDTENANTURL/Security/StartAuthentication" -d "$BODY_JSON")

# Advance Authentication
# POST /Security/AdvanceAuthentication
# Content-Type: application/json
# {
#   "Action": "Answer",
#   "SessionId": "AAAA-BBB-EXAMPLE",
#   "MechanismId": "EXAMPLERSMrV1LuSPs59ejp4yAW8gmPXIQTEXAMPLE",
#   "Answer": "HelloWorld!@"
#  }
SESSID=$(echo $START | jq -r '.Result.SessionId')
MECHID=$(echo $START | jq -r '.Result.Challenges[0].Mechanisms[0].MechanismId')
BODY_JSON=$(jq -n --arg SessionId $SESSID --arg MechanismId $MECHID --arg Answer "$IDPASS" '{"Action":"Answer"} + $ARGS.named')
TOKEN_RESPONSE=$(curl -s -XPOST -H 'Content-Type: application/json' "$IDTENANTURL/Security/AdvanceAuthentication" -d "$BODY_JSON")

TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.Result.Token')
echo -n "$TOKEN"
