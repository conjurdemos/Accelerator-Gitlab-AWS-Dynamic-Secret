#!/usr/bin/env bash

if [ -z "AWS_ACCESS_KEY_ID" ] || [ -z "AWS_SECRET_ACCESS_KEY" ]; then
    echo "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in the environment"
    echo "then run this script again"
    exit 1
fi

export MY_CUSTOM_USER="$1"
if [ -z "$MY_CUSTOM_USER" ] ; then
    echo "Usage: $0 <MY_CUSTOM_USER>"
    exit 1
fi

export MY_CUSTOM_ROLE="${1}-role"
export DIR_FOR_NEW_CREDS="./$1"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p $SCRIPT_DIR/$DIR_FOR_NEW_CREDS
if [ $? -ne 0 ]; then
    echo "Failed to create directory $DIR_FOR_NEW_CREDS"
    exit 1
fi

ANSIBLE_KEEP_REMOTE_FILES=1 ansible-playbook -vvv ${SCRIPT_DIR}/new-iam-user.yml -e "new_user_name=$MY_CUSTOM_USER new_role_name=$MY_CUSTOM_ROLE dir_for_creds=$DIR_FOR_NEW_CREDS"
