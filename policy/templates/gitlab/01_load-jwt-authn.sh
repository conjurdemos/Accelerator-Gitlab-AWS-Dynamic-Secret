#!/usr/bin/env bash
[ -z "$1" ] && echo "Usage: $0 AUTHNAME (from authn-jwt/AUTHNAME)" && exit 1

AUTHNAME="$1"
APPNAME="${AUTHNAME}-apps"

# DEFAULT_CONJUR_CLI="$(command -v conjur)"
# DEFAULT_CONJUR_CLI="${DEFAULT_CONJUR_CLI:-./bin/conjur}"
# CONJUR_CLI="${CONJUR_CLI:-$DEFAULT_CONJUR_CLI}"

# if ! command -v $CONJUR_CLI 2>&1 /dev/null; then
#   echo "Conjur CLI not found.  Please install it and make sure it is in your PATH."
#   exit 1
# fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POLICY_DIR="$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"

# $CONJUR_CLI policy update -f $POLICY_DIR/conjur/01_authn-jwt-authenticator.yml -b conjur/authn-jwt

# $CONJUR_CLI variable set -i conjur/authn-jwt/$AUTHNAME/token-app-property -v 'namespace_path'
# # this should match the value set in authn-jwt-workloads.yml as the policy name
# $CONJUR_CLI variable set -i conjur/authn-jwt/$AUTHNAME/identity-path -v "data/$APPNAME"
# $CONJUR_CLI variable set -i conjur/authn-jwt/$AUTHNAME/issuer -v 'https://gitlab.com'
# $CONJUR_CLI variable set -i conjur/authn-jwt/$AUTHNAME/jwks-uri -v 'https://gitlab.com/oauth/discovery/keys'

# $CONJUR_CLI authenticator enable --id authn-jwt/${AUTHNAME}

bash $BIN_DIR/conjurcloud-patch-policy.sh conjur/authn-jwt "$POLICY_DIR/conjur/01_authn-jwt-authenticator.yml"

bash $BIN_DIR/conjurcloud-set-variable.sh "conjur/authn-jwt/$AUTHNAME/token-app-property" 'namespace_path'
bash $BIN_DIR/conjurcloud-set-variable.sh "conjur/authn-jwt/$AUTHNAME/identity-path" "data/$APPNAME"
bash $BIN_DIR/conjurcloud-set-variable.sh "conjur/authn-jwt/$AUTHNAME/issuer" 'https://gitlab.com'
bash $BIN_DIR/conjurcloud-set-variable.sh "conjur/authn-jwt/$AUTHNAME/jwks-uri" 'https://gitlab.com/oauth/discovery/keys'

bash $BIN_DIR/conjurcloud-enable-authenticator.sh authn-jwt/${AUTHNAME}


