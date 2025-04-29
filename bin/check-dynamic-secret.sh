#!/usr/bin/env bash

# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/developer/conjur_api_issuer-ephemerals.htm
# REF: https://docs.cyberark.com/conjur-cloud/latest/en/content/conjurcloud/apis/ccl-api-secrets-dynamic.htm#Retrievedynamicsecret

source local.env

export VERBOSE="${VERBOSE:-no}"

print_usage_and_exit() {
    [ -n "$1" ] && echo "$1"
    echo "Usage: $0 <SECRET_PATH> <IAM_USER_DIR>"
    echo "   Ex: $(basename $0) data/dynamic/example-secret1 ./iam/example-user1"
    exit 1
}
slog() {
    if [ "$VERBOSE" = "yes" ]; then
        printf '%s\n' "$1"
    fi
}

if [ $# -ne 2 ]; then
    print_usage_and_exit
fi

SECRET_PATH=$(printf '%s' "$1" | jq -sRr @uri)
IAM_USER_DIR="$2"

if ! [[ "$SECRET_PATH" =~ "dynamic" ]]; then 
    print_usage_and_exit "Invalid SECRET_PATH"
fi
if [ ! -d "$IAM_USER_DIR" ]; then
    print_usage_and_exit "Invalid IAM_USER_DIR: Directory does not exist"
fi
if [ -z "$CONJ_URL" ]; then
    echo "Set CONJ_URL in the environment"
    echo "then run this script again"
    exit 3
fi

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONJ_TOKEN=$(bash $SCRIPT_DIR/conjurcloud-authenticate.sh)

##
## Check the IAM user 
##
source $IAM_USER_DIR/new-user-aws-creds.txt
source $IAM_USER_DIR/new-user-aws-info.txt

export AWS_ACCESS_KEY_ID="$NEW_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$NEW_AWS_SECRET_ACCESS_KEY"

slog "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
slog "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"

USER_ID=$(aws sts get-caller-identity)
slog "$(echo $USER_ID | jq .)"

##
## Check the IAM role
##
ROLE_INFO=$(aws sts assume-role --role-arn $NEW_ROLE_ARN --role-session-name "dh-curl-client")
slog "$(echo $ROLE_INFO | jq .)"

export AWS_ACCESS_KEY_ID=$(echo $ROLE_INFO | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_INFO | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ROLE_INFO | jq -r '.Credentials.SessionToken')

ASSUME_INFO=$(aws sts get-caller-identity)
slog "$(echo $ASSUME_INFO | jq .)"

##
## Check the Dynamic Secret
##

# GET /api/secrets/dynamic/{SECRET_PATH}/permissions
URL="$CONJ_URL/api/secrets/dynamic/$SECRET_PATH/permissions"
DYN_PERMS=$(curl -s -XGET -H "Authorization: Token token=\"$CONJ_TOKEN\"" -H "Accept: application/x.secretsmgr.v2+json" $URL)
slog "Dynamic Secret Permissions:"
slog "$(echo $DYN_PERMS | jq .)"


URL="$CONJ_URL/api/secrets/conjur/variable/$SECRET_PATH"
DYN_TOKEN=$(curl -s -XGET -H "Authorization: Token token=\"$CONJ_TOKEN\"" -H "Accept: application/x.secretsmgr.v2+json" $URL)
slog "Dynamic Secret Response:"
slog "$(echo "$DYN_TOKEN" | jq .)"

export ROLE_ARN=$(echo "$DYN_TOKEN" | jq -r '.data.assumed_role_user_arn')
export AWS_ACCESS_KEY_ID=$(echo "$DYN_TOKEN" | jq -r '.data.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(echo "$DYN_TOKEN" | jq -r '.data.secret_access_key')
export AWS_SESSION_TOKEN=$(echo "$DYN_TOKEN" | jq -r '.data.session_token')

slog "Conjur Role ARN: $ROLE_ARN"
slog "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
slog "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
slog "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

echo "Dynamic Secret Credentials Get Caller Identity Response:"
aws sts get-caller-identity

# URL - https://cybr-secrets.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fdynamic%2Fdh-glab80-secret1
# + URL=https://cybr-secrets.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fdynamic%2Fdh-glab80-secret1

# conjur:user:david_hisel@cyberark.cloud.3357 tried to fetch conjur:variable:data/dynamic/dh-glab80-secret1/permissions: 
# CONJ00076E Variable conjur:variable:data/dynamic/dh-glab80-secret1/permissions is empty or not found.


# URL - https://cybr-secrets.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fdynamic%2Fdh-glab80-secret1
#       https://cybr-secrets.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fdynamic%2Fdh-glab80-secret1
# curl -s -XGET -H 'Authorization: Token token="xxxxx="'
# -H 'Accept: application/x.secretsmgr.v2+json' 
