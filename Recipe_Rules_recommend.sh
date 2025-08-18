#!/bin/bash

# Tenancy OCID を config から取得
#TENANCY_OCID="$OCI_TENANCY"
TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq

# 出力ディレクトリ作成
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="ProblemList_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

# Oracle管理のDetector Recipeをすべて取得し、各レシピに対してルールを抽出
oci cloud-guard detector-recipe list \
  --compartment-id "$TENANCY_OCID" \
  --all \
  --query "data.items[?owner=='ORACLE'].{Detector:detector, OCID:id}" \
  --output json |
  jq -c '.[]' | while read -r recipe; do

    RECIPE_ID=$(echo "$recipe" | jq -r '.OCID')
    DETECTOR=$(echo "$recipe" | jq -r '.Detector')

    # OCID末尾8文字を識別子としてファイル名に追加
    SHORT_ID=$(echo "$RECIPE_ID" | tail -c 9)
    OUTPUT_FILE="${OUTPUT_DIR}/${DETECTOR}_${SHORT_ID}.csv"

    # ヘッダー行
    echo '"Detector","ID","Name","Description","Recommendation","DocURL"' > "$OUTPUT_FILE"

    # ルール取得と出力
    oci cloud-guard detector-recipe-detector-rule list \
      --compartment-id "$TENANCY_OCID" \
      --detector-recipe-id "$RECIPE_ID" \
      --all \
      --query 'data.items[*].{
        Detector: detector,
        ID: id,
        Name: "display-name",
        Description: "description",
        Recommendation: "recommendation"
      }' \
      --output json | jq -r --arg DETECTOR "$DETECTOR" '
        def map_detector(d):
          if d == "IAAS_CONFIGURATION_DETECTOR" then "config"
          elif d == "IAAS_ACTIVITY_DETECTOR" then "activity"
          elif d == "IAAS_THREAT_DETECTOR" then "threat"
          elif d == "IAAS_INSTANCE_SECURITY_DETECTOR" then "wlp"
          else "unknown"
          end;

        .[] |
        .Short = map_detector($DETECTOR) |
        .DocURL = "https://docs.oracle.com/en-us/iaas/Content/cloud-guard/using/detect-recipes.htm#detect-recipes-ref-" + .Short + "__" + .ID |
        [
          .Detector,
          .ID,
          .Name,
          .Description,
          .Recommendation,
          .DocURL
        ] | @csv
      ' >> "$OUTPUT_FILE"


done
