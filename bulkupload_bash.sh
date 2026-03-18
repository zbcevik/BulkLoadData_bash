echo "🚀 Starting bulkupload_bash.sh"
API_TOKEN="40fac471-f5ef-4408-88b3-0cf69e6a6f2c"
HOSTNAME="https://demo.borealisdata.ca"
DATAVERSE_ALIAS="zeynepcevik"
DIRECTORY="Datasets"
WAIT=0
CONTACT_EMAIL="${CONTACT_EMAIL:-zeynep.cevik@utoronto.ca}"

add_dataset_contact_email() {
    local metadata_file="$1"
    local email="$2"

    if [ ! -f "$metadata_file" ]; then
        echo "❌ Metadata file not found: $metadata_file"
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)

    jq --arg email "$email" '
      .datasetVersion.metadataBlocks.citation.fields |=
      map(
        if .typeName == "datasetContact" and .typeClass == "compound" then
          .value |= map(
            if has("datasetContactEmail") then
              .
            else
              . + {"datasetContactEmail": {"typeName": "datasetContactEmail", "multiple": false, "typeClass": "primitive", "value": $email}}
            end
          )
        else
          .
        end
      )
    ' "$metadata_file" > "$tmp_file" && mv "$tmp_file" "$metadata_file"
}

for datasetDir in "$DIRECTORY"/* ; do
    echo "Preparing $datasetDir ..."
    if ! add_dataset_contact_email "$datasetDir/metadata.json" "$CONTACT_EMAIL"; then
        echo "⚠️ Skipping $datasetDir due to metadata update failure"
        continue
    fi

    echo "Creating the dataset from $datasetDir ..."
    OUTPUT=$(jq 'del(.datasetVersion.files)' "$datasetDir/metadata.json" | \
          curl -s -X POST -H "Content-type:application/json" \
          -d @- "$HOSTNAME/api/dataverses/$DATAVERSE_ALIAS/datasets/?key=$API_TOKEN")


    echo "Response: $OUTPUT"

    DOI=$(echo "$OUTPUT" | grep -o '"persistentId":"[^"]*"' | cut -d'"' -f4)
    echo "Extracted DOI: $DOI"

    if [ -z "$DOI" ]; then
        echo "❌ No DOI found — skipping file upload for $datasetDir"
        continue
    fi

    filesize=$(du -k "$datasetDir/files.zip" 2>/dev/null | cut -f1)
    echo "Filesize is $filesize KB — uploading..."

    curl -u "$API_TOKEN": --data-binary @"$datasetDir/files.zip" \
        -H "Content-Disposition: filename=files.zip" \
        -H "Content-Type: application/zip" \
        -H "Packaging: http://purl.org/net/sword/package/SimpleZip" \
        "$HOSTNAME/dvn/api/data-deposit/v1.1/swordv2/edit-media/study/$DOI"

    echo "Done with $datasetDir"
    echo "--------------------------------"
done
