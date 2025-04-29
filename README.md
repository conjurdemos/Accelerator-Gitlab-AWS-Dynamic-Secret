<img alt="CyberArk Banner" src="images/cyberark-banner.jpg">

<!-- omit from toc -->
# Summary

The Conjur Cloud AWS Dynamic Secrets purpose is to allow a workload to authenticate to Conjur Cloud and subsequently obtain an AWS Session token for an IAM role.  This session token can be used to perform actions in AWS that are permitted by the role.

This accelerator describes how to set up Conjur Cloud AWS Dynamic Secrets and use them within a GitLab CI pipeline. The second part provides an example of a GitLab CI pipeline that fetches the dynamic secret and uses it.

Here is the list of technologies that will be used in this accelerator:

- [Conjur Cloud account](https://www.cyberark.com/products/multi-cloud-secrets/?utm_source=github&utm_content=gitlab-aws-dynamic-secret-accelerator)
- [Conjur Cloud AWS Dynamic Secrets](https://docs.cyberark.com/conjur-cloud/latest/en/content/operations/dynamic-secrets-aws.htm)
- [Conjur Cloud GitLab JWT Authenticator](https://docs.cyberark.com/conjur-cloud/latest/en/content/integrations/gitlab.htm)
- [GitLab Account](https://gitlab.com/)
- [GitLab CI](https://docs.gitlab.com/ci/)
- AWS Account and user with permissions to create IAM users and roles

<!-- omit from toc -->
# Table of Contents

- [Getting Conjur Cloud AWS Dynamic Secret Setup (START HERE)](#getting-conjur-cloud-aws-dynamic-secret-setup-start-here)
  - [Common Config Info](#common-config-info)
  - [Prepare The Environment](#prepare-the-environment)
  - [AWS - IAM Create User](#aws---iam-create-user)
  - [CyberArk Identity - Create User](#cyberark-identity---create-user)
  - [Privilege Cloud](#privilege-cloud)
  - [Conjur Cloud](#conjur-cloud)
- [Gitlab CI Pipeline Example](#gitlab-ci-pipeline-example)
- [Contributing](#contributing)
- [License](#license)

# Getting Conjur Cloud AWS Dynamic Secret Setup (START HERE)

❗🔴 **Each section has a list of steps to run.**

❗🔴 **It is recommended to proceed through each section in the order presented.**

## Common Config Info

Copy the `local.env-example` as `local.env` and edit the file. Change the variable values to reflect your environment.

| Variable Name            | Example                                          | Description                                                                                                                |
|--------------------------|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| IDTENANTURL              | <https://TENANT_ID.id.cyberark.cloud>            | Identity tenant base url, NO trailing slash                                                                                |
| IDUSER                   | example-user1@cyberark.cloud.00000               | Identity user with privileges to create users, add users to roles, create safes, add members to safes, and perform admin actions in Conjur Cloud |
| IDPASS                   | Example-User-Pass123                             | Identity user's password                                                                                                  |
| CONJ\_URL                | <https://MY_SUBDOMAIN.secretsmgr.cyberark.cloud> | Conjur Cloud url for your tenent                                                                                           |
| AWS\_ACCESS\_KEY\_ID     | ASIAIOSFODNN-EXAMPLE                             | AWS Access Key ID for IAM user that will be used to create users and roles                                                 |
| AWS\_SECRET\_ACCESS\_KEY | xJalrXxxxFEMI/K7MXXXG/bPxRxxC-EXAMPLEKEY         | AWS Secret Access Key for IAM user that will be used to create users and roles                                             |

_**File template for `local.env`:**_

```bash
# local.env
export IDTENANTURL="https://TENANT_ID.id.cyberark.cloud"
export IDUSER="example-user1@cyberark.cloud.00000"
export IDPASS="Example-User-Pass"

export CONJ_URL="https://MY_SUBDOMAIN.secretsmgr.cyberark.cloud"

export AWS_ACCESS_KEY_ID="ADMIN_USER_KEY"
export AWS_SECRET_ACCESS_KEY="ADMIN_USER_SECRET"
```

## Prepare The Environment

:exclamation::exclamation::warning: NOTE:

:exclamation::exclamation::warning: All commands are run inside this environment.

:exclamation::exclamation::warning: If the python virtual environment is not activated, this could cause scripts to fail.

These tools must be installed in the environment where this accelerator will be run:

- Python3
- Ansible
- bash
- Curl
- jq / yq

Run the bootstrap script and activate the environment. This step requires that Python3 is installed.

_**Bash commands to run:**_

```bash
# prepare the env with python venv and ansible
bash bin/bootstrap.sh
source .venv/bin/activate
```

## AWS - IAM Create User

This accelerator provides an ansible playbook that will create the AWS IAM user and role that are needed for the authenticator and dynamic secret.

### Requirements - Ansible and AWS

- An AWS account with permissions to
  - Create IAM users and roles
  - Create IAM policies
- An AWS Access Key ID and Secret Access Key for the account
- Python 3 installed on your local machine where you intend to run this.

### Using Ansible

1. Set the AWS\_ACCESS\_KEY\_ID and AWS\_SECRET\_ACCESS\_KEY environment variables with credentials of the user with create user/policy permissions. (See [Common Config Info](#common-config-info))
2. Run the script, `iam/provision-iam-user.sh`.

    _**Bash commands to run:**_

    ```bash
    # Ensure AWS variables are set in `local.env` for the AWS admin user
    edit local.env 
    
    source local.env
    
    # From the base project directory
    bash iam/provision-iam-user.sh example-user1
    
    # NOTE: In this example, new user creds are stored in dir named ./iam/example-user1/
    ```

## CyberArk Identity - Create User

_**Manual steps to run:**_

1. Log in to the CyberArk Identity Admin Portal.
2. Navigate to "Users" and click "Add User".
3. Fill in the required fields:
    - Username: Enter a unique username (Ex: `example-user1` @cyberark.cloud.0000).
    - Email: Provide a valid email address.
    - First Name and Last Name: Enter appropriate values.
4. Set the password for the user and ensure the following attributes are selected:
    - Is OAuth confidential client
    - Is service user
    - Password never expires
5. Click Create User and note the credentials for future use.
6. <span style="color:red;font-weight:bold">IMPORTANT STEP</span> - Add the user to the following roles:

    - In Identity, click on Roles, search for each role, then add the new user to these roles:
        - `Secrets Manager - Conjur Cloud Admin`
        - `Privilege Cloud Users`

## Privilege Cloud

_**Manual steps to run:**_

### 1. Create A Safe

1. Log in to the CyberArk Privilege Cloud Web Interface.
2. Navigate to "Safes" and click "Create Safe".
3. Fill in the required fields:
    - Safe Name: Enter a unique name for the safe (Ex: "ExampleSafe").
    - Description: Provide a description for the safe.
    - Number of Versions Retained: Set the desired number of versions to retain.
    - Retention Period (Days): Specify the retention period for the safe.
4. Click "Save" to create the safe.

### 2. Enable Conjur Sync On The Safe

1. Open the safe (Ex: "ExampleSafe").
2. Navigate to the "Members" tab.
3. Click "Add Members".
4. Select "System Component Users" from the pulldown.
5. Add "Conjur Sync" user as a member of the Safe, with the following permissions.

| Role     | Permissions                                          |
|----------|------------------------------------------------------|
| Access   | "List accounts", "Use accounts", "Retrieve accounts" |
| Workflow | "Access Safe without confirmation"                   |

### 3. Add Service Account As A Member To The Safe

1. Open the safe (Ex: "ExampleSafe").
2. Navigate to the "Members" tab.
3. Click "Add Members".
4. Search for the user or group you want to add (Ex: `example-user`).
5. Select the desired permissions for the member (Ex: "Full Control" or "Use Accounts").
6. Click "Add" to save the changes.

## Conjur Cloud

### Create Issuer

Create an issuer in Conjur Cloud using the aws credentials from the AWS User.

This script will create an issuer using the credentials created for USERNAME, example "example-user1". If you used the ansible playbook to create your user, then the creds will be in the `iam/USERNAME/*` directory.

Set the AWS variables, NEW\_AWS\_ACCESS\_KEY\_ID
NEW\_AWS\_SECRET\_ACCESS\_KEY with the credentials of the new user.

Run the `bin/create-issuer.sh` script and specify the issuer name and
the max ttl as parameters.

Note the issuer name for use with the policy wizard.

_**Bash commands to run:**_

```bash
# From the base project directory

# Ensure the python env is active
source .venv/bin/activate

# Ensure variables are set in `local.env`
edit local.env 

# IAM User is already provisioned
# Load the AWS vars with new user creds
export NEW_AWS_ACCESS_KEY_ID NEW_AWS_SECRET_ACCESS_KEY

source iam/example-user1/new-user-aws-creds.txt

# Create the conjur issuer
#   Usage: create-issuer.sh <ISSUER_ID> <MAX_TTL>
bash bin/create-issuer.sh example-issuer 900
```

**NOTE: the issuer name created here will be used in the policy wizard.**

### Create Gitlab JWT Authenticator and Dynamic Secret

This accelerator uses a code wizard to help generate the needed Conjur policies.

After the wizard is done, the Conjur policy files will reside in the directory `./policy/ENVIRONEMT` where ENVIRONMENT is specified in the wizard.  E.g. the ENVIRONMENT "gitlab6" would result in policies stored in the directory, `./policy/gitlab6/`.

Here is a table with the list of quesions asked by the wizard, and a description of the answer to provide.

| Question                                                                         | Answer Description                                                                                                                                                                                                                                                                                         |
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|                                                                                  | **Gather Facts**                                                                                                                                                                                                                                                                                           |
| Please enter an issuer name:                                                     | Enter the name of the issuer that was created in a previous step.                                                                                                                                                                                                                                          |
| Please enter the safename:                                                       | Enter the name of the safe that was created in a previous step.                                                                                                                                                                                                                                            |
| Please enter the environment (default is 'dev'):                                 | Enter the name of your environment (this will be used to create a directory under ./policy/ and it will store all the conjur policies for that environement).                                                                                                                                              |
| Please enter the name of the new authenticator:                                  | Enter the name of the **NEW** authenticator that will be created with this wizard.                                                                                                                                                                                                                         |
|                                                                                  | **Create Host Section**                                                                                                                                                                                                                                                                                    |
| Please enter the new host name:                                                  | IMPORTANT: the host name must match the `namespace_path` set in the gitlab JWT token.  This is usually the top level path of the account, e.g. for the account <https://gitlab.com/EXAMPLE-USER1>, the namespace_path is `EXAMPLE-USER`, so, find the namespace_path of your project, and enter that here. |
| Select the 'Finished' item when you are done selecting the claims.               | This is a select list to determine which JWT claims will be used to authenticate to conjur.  Select the item `Finished` when you are finished specifying which claims to use. Here is the [gitlab doc](https://about.gitlab.com/blog/2023/02/28/oidc/) explainer.                                          |
| Now that the claims have been selected, enter the values for each of the claims. | Each of the claims that were selected will be shown and the wizard will ask for the values that will need to match when Gitlab provides the JWT token to conjur. E.g. For the `ref` claim, provide the branch name that will be allowed to authenticate to conjur.                                         |
|                                                                                  | **Create Dynamic Secret Section**                                                                                                                                                                                                                                                                          |
| Choose whether to use an assumed role or a federation token.                     | Assumed role will require the role ARN created from the previous step.                                                                                                                                                                                                                                     |
| Please enter Dynamic Secret name:                                                | Enter the name of the dynamic secret that will be created.                                                                                                                                                                                                                                                 |
| Please enter Dynamic Secret Assumed Role ARN:                                    | **IF you chose `Assumed Role`**, then find the ARN of the role that was created in the `./iam/USERNAME/new-user-aws-info.txt` file, USERNAME is the value used to create the new IAM user in a previous step.                                                                                              |
| Please enter Dynamic Secret AWS Region:                                          | This is the region that the role should use, e.g. `us-east-1`.                                                                                                                                                                                                                                             |
| Please enter Dynamic Secret TTL:                                                 | TTL for the dynamic secret, minimum: 900, maximum: no bigger than TTL set in the issuer.                                                                                                                                                                                                                   |

Run the policy wizard script, `/policy/jwt-policy-wizard.sh`.

_**Bash commands to run:**_

```bash
# From the project base directory
bash policy/jwt-policy-wizard.sh
```

### Check The Dynamic Secret

Run the `bin/check-dynamic-secret.sh` script.

The first parameter is the path to the dynamic secret, this can be found in the conjur UI under Secrets, usually it will be `data/dynamic/DYNAMIC_SECRET_NAME` that was entered in the wizard.

The second parameter is the path to the iam user directory that was created in the ansible step to create the IAM user and role.

_**Bash commands to run:**_

```bash
# Usage bin/check-dynamic-secret.sh "path to secret" "iam user dir"
bash bin/check-dynamic-secret.sh data/dynamic/example-secret1 ./iam/example-user1

# Alternatively...

# Show all the values gathered along the way, set VERBOSE=yes
VERBOSE=yes bash bin/check-dynamic-secret.sh data/dynamic/example-secret1 ./iam/example-user1
```

# Gitlab CI Pipeline Example

This is an example pipeline that will retrieve the AWS Dynamic secret and use it in a call to `aws sts get-caller-identity`

| Placeholder         | Value                                                                                                 |
|---------------------|-------------------------------------------------------------------------------------------------------|
| YOUR-SUBDOMAIN      | Your conjur cloud sub-domain.                                                                         |
| AUTHENTICATOR-NAME  | The name you entered in the wizard for question, "`Please enter the name of the new authenticator:`". |
| DYNAMIC-SECRET-NAME | The name you entered in the wizard for question, "`Please enter Dynamic Secret name:`".               |

Save this file as `.gitlab-ci.yml` in your Gitlab project base directory.

Kick off a new pipeline. The job should finish and the `aws sts get-caller-id` command should show the role information for the role created.

_**File template for `.gitlab-ci.yml`:**_

```yaml
stages:
- job_with_aws_session_token

job_with_aws_session_token:
  stage: job_with_aws_session_token
  image: alpine:latest
  id_tokens:
    ID_TOKEN_1:
      aud: https://gitlab.com
  variables:
    # Change YOUR-SUBDOMAIN, AUTHENTICATOR-NAME, DYNAMIC-SECRET-NAME to reflect your setup
    CONJUR_APPLIANCE_URL: "https://YOUR-SUBDOMAIN.secretsmgr.cyberark.cloud/api"
    CONJUR_ACCOUNT: "conjur"
    CONJUR_AUTHN_JWT_SERVICE_ID: "AUTHENTICATOR-NAME"
    CONJUR_AUTHN_JWT_TOKEN: $ID_TOKEN_1
    CONJUR_RETRIEVE_QPATH: "secrets/conjur/variable"
    CONJUR_VARIABLE_ID: "data/dynamic/DYNAMIC-SECRET-NAME"
  script:
    - apk --no-cache add jq curl aws-cli
    - |
      # POST https://<subdomain>.secretsmgr.cyberark.cloud/api/authn-jwt/<service-id>/conjur/authenticate
      export CONJUR_SESSION_TOKEN=$(curl -sk -XPOST "$CONJUR_APPLIANCE_URL/authn-jwt/$CONJUR_AUTHN_JWT_SERVICE_ID/conjur/authenticate" \
      -H "Content-Type:application/x-www-form-urlencoded" \
      -H "Accept-Encoding:base64" \
      --data-urlencode "jwt=$CONJUR_AUTHN_JWT_TOKEN")
    - export SECRET_PATH=$(printf '%s' "$CONJUR_VARIABLE_ID" | jq -sRr @uri)
    - export RESPONSE=$(curl -sk -XGET -H "Authorization:Token token=\"${CONJUR_SESSION_TOKEN}\"" $CONJUR_APPLIANCE_URL/$CONJUR_RETRIEVE_QPATH/$SECRET_PATH)
    - export AWS_ACCESS_KEY_ID=$(echo $RESPONSE | jq -r '.data.access_key_id')
    - export AWS_SECRET_ACCESS_KEY=$(echo $RESPONSE | jq -r '.data.secret_access_key')
    - export AWS_SESSION_TOKEN=$(echo $RESPONSE | jq -r '.data.session_token')
    - aws sts get-caller-identity
```

# Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get started and descriptions of our development workflows, please see our guides.

- [Contributing](CONTRIBUTING.md)
- [Security Policies and Procedures](SECURITY.md)

# License

Copyright (c) 2025 CyberArk Software Ltd. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

For the full license text see [LICENSE](LICENSE).
