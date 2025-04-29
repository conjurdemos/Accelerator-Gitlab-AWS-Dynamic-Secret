#!/usr/bin/env bash

# conjur policy load -f my-aws-workload-permissions-on-dyn-secret.yml -b data/dynamic

#!/usr/bin/env bash
function usage() {
    echo "Usage: $0 POLICY_FILE"
    echo "  POLICY_FILE - policy file for dynamic secret grants"
    echo "                Ex: 11_dynamic-secret-grants.yml"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

POLICY_FILE="$1"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POLICY_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"

bash $BIN_DIR/conjurcloud-post-policy.sh data/dynamic "$POLICY_DIR/data/$POLICY_FILE"
