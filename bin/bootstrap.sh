#!/usr/bin/env bash

#* install python virtualenv
python3 -m venv .venv
source .venv/bin/activate

#* AWS cli is needed to run the checker scripts
if ! command -v aws >/dev/null 2>&1 || ! aws --version 2>/dev/null | grep -q 'aws-cli/2'; then
    echo "AWS CLI v2 is required. Please install it and try again."
    exit 1
fi

#* install pip modules into .venv
pip install --upgrade pip
pip install ansible
pip install botocore
pip install boto3

#* install ansible modules
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install community.general
