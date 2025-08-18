#!/bin/bash

#前処理

timestamp=$(date '+%Y%m%d_%H%M%S')

output_dir="RecipeConfig_${timestamp}"
mkdir -p "$output_dir"

# Tenancy OCID を取得 (cloud shell)

TENANCY_OCID="$OCI_TENANCY"
#TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq


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
    SUFFIX="${RECIPE_ID: -8}"  # OCIDの末尾8桁を抽出
    OUTPUT_FILE="${output_dir}/${DETECTOR}_${SUFFIX}.csv"

    # 出力ファイルを初期化（ヘッダーは必要に応じて付け加えてください）
    echo '"Detector","ID","Name","RiskLevel","IsEnabled","IsConfigAllowed","Labels","Configurations..."' > "$OUTPUT_FILE"

    # ルールを抽出してファイルに保存（上書き）
    oci cloud-guard detector-recipe-detector-rule list \
      --compartment-id "$TENANCY_OCID" \
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
