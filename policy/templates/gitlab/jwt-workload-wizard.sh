#!/usr/bin/env bash

# Purpose of this script is to prompt user for info, then update the conjur policies.  
# Loading the policies is handled in the caller script.

AUTHNAME="$1"
WORKLOADFILE="$2" # full path is passed as a parameter
DYNSECRET_GRANTSFILE="$3" # full path is passed as a parameter
if [ -z "$AUTHNAME" ] || [ -z "$WORKLOADFILE" ] || [ -z "$DYNSECRET_GRANTSFILE" ]; then
    echo "Usage: $(basename $0) AUTHNAME WORKLOAD_YAML_FULL_FILE_PATH DYNSECRET_GRANTS_YAML_FULL_FILE_PATH"
    exit 1
fi

JWT_AUTHNAME="authn-jwt/$AUTHNAME"

# set policy id
yq eval --inplace ".[].id = \"${AUTHNAME}-apps\"" $WORKLOADFILE

echo "Please enter the new workload/host name."
echo "NOTE: this should be the name of the Gitlab namespace_path"
echo "      Example: mygroup"
read -p "Please enter the new host name: " conjur_host_name
echo "You entered: $conjur_host_name"

# set the host id
yq eval --inplace ".[].body[1][0].id = \"$conjur_host_name\"" $WORKLOADFILE

echo "In order to create the annotations, you will need to specify the matching claims."

printf '%s' <<EOF
{
# Strongly recommend using at least one of these claims
  "ref": "auto-deploy-2020-04-01",
  "project_path": "mygroup/myproject",
  "project_id": "22",

# Use these if you want to restrict the workload to a specific claim
  "namespace_id": "1",
  "namespace_path": "mygroup",
  "user_id": "42",
  "user_login": "myuser",
  "user_email": "myuser@example.com",
  "pipeline_source": "web",
  "environment": "production",
  "environment_protected": "true",
}
EOF

items=("Finished"
"ref"
"project_path"
"project_id"
"namespace_id"
"namespace_path"
"user_id"
"user_login"
"user_email"
"pipeline_source"
"environment"
"environment_protected")

echo "Select the 'Finished' item when you are done selecting the claims."
selected_items=()
until  [ $item == "Finished" ]; do
    echo "Please select an item (select Finished when done):"
    select item in "${items[@]}"; do
    if [[ -n "$item" ]]; then
        if [ "$item" != "Finished" ]; then
            selected_items+=($item)
            echo "You selected: $item"
        fi
        break
    else
        echo "Invalid selection. Please try again."
    fi
    done
done

echo "Now that the claims have been selected, enter the values for each of the claims."

declare -A annotations

for item in "${selected_items[@]}"; do
    read -p "Enter value for $item: " value
    annotations["$item"]="$value"
done

QQ='"'
annotation_items=()
for key in "${!annotations[@]}"; do
    note="${QQ}${JWT_AUTHNAME}/$key${QQ}:${QQ}${annotations[$key]}${QQ}"
    annotation_items+=($note)
done

# Join items with ","
{ # scope IFS to local context
IFS=,
annotations_rendered="{${annotation_items[*]}}"
}

echo "$annotations_rendered"

# construct the annotations in the host
yq eval --inplace ".[].body[1][0].annotations = $annotations_rendered"  $WORKLOADFILE

# Add Host for dyn secret grant
yq eval --inplace ".[].role = \"/data/${AUTHNAME}-apps/$conjur_host_name\"" "$DYNSECRET_GRANTSFILE"
