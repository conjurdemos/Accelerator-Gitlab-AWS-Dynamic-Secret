#!/usr/bin/env bash
function usage() {
    echo "Usage: $0 AUTHNAME SAFENAME"
    echo "  AUTHNAME - from authn-jwt/AUTHNAME"
    echo "  SAFENAME - Privilege Cloud safe name" 
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

AUTHNAME="$1"
SAFENAME="$2"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POLICY_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"

# $CONJUR_CLI policy load -f $POLICY_DIR/data/01_authn-jwt-workloads.yml -b data
# $CONJUR_CLI policy load -f $POLICY_DIR/conjur/02_authn-jwt-grants.yml -b conjur/authn-jwt/$AUTHNAME
# $CONJUR_CLI policy load -f $POLICY_DIR/data/02_secrets-grants.yml -b data/vault/$SAFENAME

bash $BIN_DIR/conjurcloud-post-policy.sh data "$POLICY_DIR/data/01_authn-jwt-workloads.yml"

bash $BIN_DIR/conjurcloud-post-policy.sh "conjur/authn-jwt/$AUTHNAME" "$POLICY_DIR/conjur/02_authn-jwt-grants.yml"

bash $BIN_DIR/conjurcloud-post-policy.sh "data/vault/$SAFENAME" "$POLICY_DIR/data/02_secrets-grants.yml"
