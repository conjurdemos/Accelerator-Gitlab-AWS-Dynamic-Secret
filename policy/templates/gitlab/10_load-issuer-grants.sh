#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename $0) <APPNAME> <ISSUER>"
    exit 1
fi
APPNAME="$1"
ISSUER="$2"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POLICY_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"

# Grant group to the issuer
yq eval --inplace ".[].members[0] = \"/data/$APPNAME\"" $POLICY_DIR/conjur/10_issuer-grants.yml 

# $CONJUR_CLI policy update -f $POLICY_DIR/conjur/10_issuer-grants.yml -b conjur/issuers/$ISSUER

bash $BIN_DIR/conjurcloud-patch-policy.sh "conjur/issuers/$ISSUER" "$POLICY_DIR/conjur/10_issuer-grants.yml"
