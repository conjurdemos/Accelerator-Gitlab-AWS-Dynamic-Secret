#!/usr/bin/env bash
function usage() {
    echo "Usage: $0 POLICY_FILE"
    echo "  POLICY_FILE - policy file for dynamic secret creation"
    echo "                10_aws-dynamic-secret-assumed-role.yml, or"
    echo "                10_aws-dynamic-secret-federated.yml"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

POLICY_FILE="$1"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POLICY_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"

# $CONJUR_CLI policy load -f $POLICY_DIR/data/$POLICY_FILE -b data/dynamic

bash $BIN_DIR/conjurcloud-post-policy.sh data/dynamic "$POLICY_DIR/data/$POLICY_FILE"
