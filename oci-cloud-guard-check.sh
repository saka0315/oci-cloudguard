#!/bin/bash
# updated 241204

#前処理

timestamp=$(date '+%Y%m%d_%H%M%S')
echo "Your tenancy: $OCI_TENANCY "

#Cloud shell
ACCOUNT_NAME=$(whoami)
echo "Your account: $ACCOUNT_NAME"

#output_dir="output_${timestamp}"
#Cloud shell
output_dir="${ACCOUNT_NAME}_${timestamp}"

mkdir -p "$output_dir"

echo "directory '$output_dir' created "

exec > >(tee -a "${output_dir}/output.log")
#exec 2> >(tee -a "${output_dir}/error.log" >&2)
exec 2>"${output_dir}/error.log"

#compartment_ocid="ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq"
#Cloud shell
compartment_ocid="$OCI_TENANCY" 

region=$(oci cloud-guard configuration get --compartment-id $compartment_ocid --query 'data."reporting-region"' --raw-output)

echo "Cloud Guard Report Region: $region "


# (1) Gather all detector recipe ocid's

#TARGET_ID="ocid1.cloudguardtarget.oc1.ap-tokyo-1.amaaaaaanyabxsyadzaicdohxopgdi3pteyqy25nnow4gejlqme4lm3erhsq"
TARGET_ID=$(oci cloud-guard target list -c "$compartment_ocid" --query 'data.items[0].id' --all --raw-output)
if [ $? -ne 0 ]; then
    echo "Error: cloud-guard target list failed "
    exit 1
fi

# 各DetectorのIDを取得
# https://docs.oracle.com/en-us/iaas/api/#/en/cloud-guard/20200131/datatypes/TargetDetectorRecipeDetectorRuleSummary
# TargetDetectorRecipeDetectorRuleSummary Reference : detector
activityid=$(oci cloud-guard target-detector-recipe list --compartment-id "$compartment_ocid" --target-id "$TARGET_ID" --all --query "data.items[?detector=='IAAS_ACTIVITY_DETECTOR'] | [0].\"detector-recipe-id\"" --raw-output)

threadid=$(oci cloud-guard target-detector-recipe list --compartment-id "$compartment_ocid" --target-id "$TARGET_ID" --all --query "data.items[?detector=='IAAS_THREAT_DETECTOR'] | [0].\"detector-recipe-id\"" --raw-output)

configid=$(oci cloud-guard target-detector-recipe list --compartment-id "$compartment_ocid" --target-id "$TARGET_ID" --all --query "data.items[?detector=='IAAS_CONFIGURATION_DETECTOR'] | [0].\"detector-recipe-id\"" --raw-output)

instanceid=$(oci cloud-guard target-detector-recipe list --compartment-id "$compartment_ocid" --target-id "$TARGET_ID" --all --query "data.items[?detector=='IAAS_INSTANCE_SECURITY_DETECTOR'] | [0].\"detector-recipe-id\"" --raw-output)

# 結果を表示（確認用）
echo "CG Activity Detector ID: $activityid"
echo "CG Threat Detector ID: $threadid"
echo "CG Configuration Detector ID: $configid"
echo "CG Instance Security Detector ID: $instanceid"


# (2) Gather all detector recipes : 

oci cloud-guard detector-recipe-detector-rule list --compartment-id $compartment_ocid --detector-recipe-id $threadid --all > ${output_dir}/all_recipes_threat_detector.json
if [ $? -ne 0 ]; then
  echo "Cloud Guard Threat detector-recipe-detector-rule list not got." 
  else
  echo "Cloud Guard Threat detector-recipe-detector-rule list successfully got." 
fi

oci cloud-guard detector-recipe-detector-rule list --compartment-id $compartment_ocid --detector-recipe-id $instanceid --all > ${output_dir}/all_recipes_instance_security.json
if [ $? -ne 0 ]; then
  echo "Cloud Guard Instance Security detector-recipe-detector-rule list not got." 
  else
  echo "Cloud Guard Instance Security detector-recipe-detector-rule list successfully got." 
fi


oci cloud-guard detector-recipe-detector-rule list --compartment-id $compartment_ocid --detector-recipe-id $configid --all > ${output_dir}/all_recipes_config_detector.json
if [ $? -ne 0 ]; then
  echo "Cloud Guard Configuration detector-recipe-detector-rule list failed." 
  exit 1
    else
  echo "Cloud Guard Configuration detector-recipe-detector-rule list successfully got." 
fi

oci cloud-guard detector-recipe-detector-rule list --compartment-id $compartment_ocid --detector-recipe-id $activityid --all > ${output_dir}/all_recipes_activity_detector.json
if [ $? -ne 0 ]; then
  echo "Cloud Guard Activity detector-recipe-detector-rule list not got." 
    else
  echo "Cloud Guard Activity detector-recipe-detector-rule list successfully got." 
fi

# (3)Gather list of problems

#oci cloud-guard problem list --compartment-id ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq --access-level ACCESSIBLE --compartment-id-in-subtree TRUE --all  > ${output_dir}/all_detected_problems.json
oci cloud-guard problem list --compartment-id $compartment_ocid --access-level ACCESSIBLE --compartment-id-in-subtree TRUE --all  > ${output_dir}/all_detected_problems.json

if [ $? -ne 0 ]; then
  echo "OCI Cloud Guard problem list failed." 
  exit 1
fi

echo "Successful gathering list of problems "

# (4) Extract problem OCID's

python3 << EOF

import json

# Load the JSON file
with open('${output_dir}/all_detected_problems.json') as f:
    data = json.load(f)

# Extract the values of the key "id"
id_values = [item["id"] for item in data["data"]["items"]]

# Save the extracted values to a file
with open('${output_dir}/problem_ocids.txt', 'w') as f:
    for ocid in id_values:
        f.write(f"{ocid}\n")

EOF

echo "Successful extract problem OCID's, then extract details of the problem for a while "

# (5) Extract all details of the problem 
# https://docs.oracle.com/en-us/iaas/api/#/en/cloud-guard/20200131/Problem/  GetProblem

# Loop through each OCID in problem_ocids.txt
while read problem_ocid; do
  # Create output file name
  output_file="${output_dir}/problem.details.$problem_ocid"

  # Run OCI CLI command
  oci cloud-guard problem get --problem-id "$problem_ocid" > "$output_file"

#  echo "Output saved to $output_file"
done < ${output_dir}/problem_ocids.txt

echo "Successful extract all detailed of the problem"

#  zip kekka Directory
zip -q -r ${output_dir}.zip ${output_dir}

echo "Successful ${output_dir}.zip created "