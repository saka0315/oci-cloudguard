#!/bin/bash

# Tenancy OCID を config から取得
TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq
#TENANCY_OCID=$(awk -F "=" '/^tenancy/ {print $2}' ~/.oci/config | xargs)

# Oracle管理のDetector Recipeをすべて取得し、各レシピに対してルールを抽出
oci cloud-guard detector-recipe list \
  --compartment-id "$TENANCY_OCID" \
  --all \
  --query "data.items[?owner=='ORACLE'].{Detector:detector, OCID:id}" \
  --output json |
  jq -c '.[]' | while read -r recipe; do

    # フィールド抽出
    RECIPE_ID=$(echo "$recipe" | jq -r '.OCID')
    DETECTOR=$(echo "$recipe" | jq -r '.Detector')
    OUTPUT_FILE="${DETECTOR}.csv"

    # ルールを抽出してファイルに保存
    oci cloud-guard detector-recipe-detector-rule list \
      --detector-recipe-id "$RECIPE_ID" \
      --all \
      --query 'data.items[*].{
        Detector: detector,
        ID: id,
        Name: "display-name",
        RiskLevel: "detector-details"."risk-level",
        IsEnabled: "detector-details"."is-enabled",
        IsConfigAllowed: "detector-details"."is-configuration-allowed",
        Labels: "detector-details".labels,
        Configurations: "detector-details"."configurations"
      }' \
      --output json | jq -r '
        .[] |
        [
          .Detector,
          .ID,
          .Name,
          .RiskLevel,
          .IsEnabled,
          .IsConfigAllowed,
          (.Labels // [] | join(","))
        ] +
        (if .Configurations != null then
          [.Configurations[] | .name, .value]
        else
          []
        end) |
        @csv
      ' >> "$OUTPUT_FILE"

done

