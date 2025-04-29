#!/usr/bin/env bash

#BASH="bash -x" # add/remove '-x' enable/disable debugging
BASH="bash" # add/remove '-x' enable/disable debugging

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Assume this wizard is running in the BASE_DIR/policy dir
BASE_DIR="$(dirname $SCRIPT_DIR)"
BIN_DIR="$BASE_DIR/bin"
if ! [ -d "$BIN_DIR" ]; then
    echo "Error: dir, $BIN_DIR, does not exist. Please run the script from the base policy directory."
    exit 1
fi

POLICY_DIR="${1:-$BASE_DIR/policy}"
TEMPL_BASE_DIR="$POLICY_DIR/templates"
if ! [ -d "$TEMPL_BASE_DIR" ]; then
    echo "Usage: $(basename $0) <POLICY_DIR> (default is $BASE_DIR/policy)"
    exit 1
fi

echo "First we need the name of an Issuer."
read -p "Please enter an issuer name: " issuer_name
echo "You entered: $issuer_name"
export ISSUER=$issuer_name


echo "The authenticator needs to be associated to a Safe."
read -p "Please enter the safename: " safe_name
echo "You entered: $safe_name"
export SAFENAME=$safe_name

echo "Now to create a directory that is associated with the environment."
echo "The Conjur policies will be stored in this directory."

read -p "Please enter the environment (default is 'dev'): " conjur_env
export conjur_env=${conjur_env:-dev}
echo "You entered: $conjur_env"

# create the directory where we store the policies
mkdir -p "$POLICY_DIR/$conjur_env"
mkdir -p "$POLICY_DIR/$conjur_env/conjur"
mkdir -p "$POLICY_DIR/$conjur_env/data"
mkdir -p "$POLICY_DIR/$conjur_env/bin"

# copy the templates into the env 
TEMPL_DIR="$TEMPL_BASE_DIR/gitlab"
cp $TEMPL_DIR/*.sh $POLICY_DIR/$conjur_env
cp $TEMPL_DIR/conjur/*.yml $POLICY_DIR/$conjur_env/conjur
cp $TEMPL_DIR/data/*.yml $POLICY_DIR/$conjur_env/data

 # make a copy of needed bin scripts; in case any mods are needed, mod the local files
cp $BIN_DIR/conjurcloud*.sh $POLICY_DIR/$conjur_env/bin  
cp $BIN_DIR/idclient-authenticate.sh $POLICY_DIR/$conjur_env/bin

# Start the question/answer session
echo "What is the name of the authenticator?  e.g. AUTH_NAME as in the part after authn-jwt/AUTH_NAME"
read -p "Please enter the name of the new authenticator: " conjur_authn
echo "You entered: $conjur_authn"

export APPNAME="${conjur_authn}-apps"

# authn policy id $conjur_authn with group "apps"
yq eval --inplace ".[].id = \"$conjur_authn\"" $POLICY_DIR/$conjur_env/conjur/01_authn-jwt-authenticator.yml

# grant "apps" role to members
yq eval --inplace ".[].members[0] = \"/data/$APPNAME\"" $POLICY_DIR/$conjur_env/conjur/02_authn-jwt-grants.yml 

# grant delegation/consumers to /data/${conjur_authn}-apps
yq eval --inplace ".[].members[0] = \"/data/$APPNAME\"" $POLICY_DIR/$conjur_env/data/02_secrets-grants.yml 

# workload wizard will update the workloads yaml
# dyn secret grants yaml requires the host name too, so, we add it from the workload wizard
$BASH $POLICY_DIR/$conjur_env/jwt-workload-wizard.sh "$conjur_authn" "$POLICY_DIR/$conjur_env/data/01_authn-jwt-workloads.yml" "$POLICY_DIR/$conjur_env/data/11_dynamic-secret-grants.yml"

$BASH $POLICY_DIR/$conjur_env/01_load-jwt-authn.sh $conjur_authn
$BASH $POLICY_DIR/$conjur_env/02_load-data-policies.sh $conjur_authn $SAFENAME

$BASH $POLICY_DIR/$conjur_env/10_load-issuer-grants.sh $APPNAME $ISSUER

# Dynamic Secret for assumed role

echo "====="
echo "Dynamic Secret Configuration"
echo ""
echo "Choose whether to use an assumed role or a federation token."
select dyn_type in "Assumed Role" "Federation Token"; do break; done

read -p "Please enter Dynamic Secret name: " dyn_name
export DYN_SECRET_NAME="$dyn_name"

# dyn secret grants yaml requires the secret name
yq eval --inplace ".[].resources = \"$DYN_SECRET_NAME\"" "$POLICY_DIR/$conjur_env/data/11_dynamic-secret-grants.yml"

export ROLE_ARN="NOT SET"
if [ "$dyn_type" = "Assumed Role" ]; then
read -p "Please enter Dynamic Secret Assumed Role ARN: " dyn_aws_role_arn
export ROLE_ARN="$dyn_aws_role_arn"
fi

read -p "Please enter Dynamic Secret AWS Region: " dyn_aws_region
export DYN_SECRET_AWS_REGION="$dyn_aws_region"

read -p "Please enter Dynamic Secret TTL: " dyn_ttl
export DYN_SECRET_TTL="$dyn_ttl"

for f in "$POLICY_DIR/$conjur_env/data/10_aws-dynamic-secret-assumed-role.yml" "$POLICY_DIR/$conjur_env/data/10_aws-dynamic-secret-federated.yml"; do
    yq eval --inplace ".[].id = \"$DYN_SECRET_NAME\"" $f
    yq eval --inplace ".[0].annotations[\"dynamic/issuer\"] = \"$ISSUER\"" $f
    yq eval --inplace ".[0].annotations[\"dynamic/role-arn\"] = \"$ROLE_ARN\"" $f
    yq eval --inplace ".[0].annotations[\"dynamic/region\"] = \"$DYN_SECRET_AWS_REGION\"" $f
    yq eval --inplace ".[0].annotations[\"dynamic/ttl\"] = $DYN_SECRET_TTL" $f 
done

export DYN_POLICY_FILE="10_aws-dynamic-secret-federated.yml"
if [ "$dyn_type" = "Assumed Role" ]; then
    DYN_POLICY_FILE="10_aws-dynamic-secret-assumed-role.yml"
fi


$BASH $POLICY_DIR/$conjur_env/20_load-dynamic-secret.sh $DYN_POLICY_FILE
$BASH $POLICY_DIR/$conjur_env/21_load-dynamic-secret-grants.sh 11_dynamic-secret-grants.yml
