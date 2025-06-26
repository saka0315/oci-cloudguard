#!/bin/bash

# Tenancy OCID を config から取得
TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaa3bgp7z6kffjkajrxckvtxfnj7lnn7cvgvqbbr4stmozk7obqdjjq

# Oracle管理のDetector Recipeをすべて取得し、各レシピに対してルールを抽出
oci cloud-guard detector-recipe list \
  --compartment-id "$TENANCY_OCID" \
  --all \
  --query "data.items[?owner=='ORACLE'].{Detector:detector, OCID:id}" \
  --output json |
  jq -c '.[]' | while read -r recipe; do

    RECIPE_ID=$(echo "$recipe" | jq -r '.OCID')
    DETECTOR=$(echo "$recipe" | jq -r '.Detector')

    # OCID末尾8文字を識別子としてファイル名に追加（複数存在する場合の衝突防止）
    SHORT_ID=$(echo "$RECIPE_ID" | tail -c 9)
    OUTPUT_FILE="${DETECTOR}_${SHORT_ID}.csv"

    # ヘッダー行を書き込み（上書き）
    echo '"Detector","ID","Name","Description","Recommendation"' > "$OUTPUT_FILE"

    # ルールを取得してCSV形式で出力
    oci cloud-guard detector-recipe-detector-rule list \
      --detector-recipe-id "$RECIPE_ID" \
      --all \
      --query 'data.items[*].{
        Detector: detector,
        ID: id,
        Name: "display-name",
        Description: "description",
        Recommendation: "recommendation"
      }' \
      --output json | jq -r '
        .[] |
        [
          .Detector,
          .ID,
          .Name,
          .Description,
          .Recommendation
        ] | @csv
      ' >> "$OUTPUT_FILE"

done
