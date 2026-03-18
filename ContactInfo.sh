#!/usr/bin/env bash

# Helper to inject email into the datasetContact block of metadata.json.
# Run as:
#   CONTACT_EMAIL='you@domain.com' bash ContactInfo.sh Datasets/dataset1/metadata.json

metadata_file="$1"
contact_email="${CONTACT_EMAIL:-zeynep.cevik@utoronto.ca}"

if [ -z "$metadata_file" ]; then
  echo "Usage: $0 path/to/metadata.json"
  exit 1
fi

if [ ! -f "$metadata_file" ]; then
  echo "Metadata file not found: $metadata_file"
  exit 2
fi

jq --arg email "$contact_email" '
  .datasetVersion.metadataBlocks.citation.fields |=
  map(
    if .typeName == "datasetContact" and .typeClass == "compound" then
      .value |= map(
        if has("datasetContactEmail") then
          .
        else
          . + {"datasetContactEmail": {"typeName":"datasetContactEmail", "multiple": false, "typeClass":"primitive", "value": $email}}
        end
      )
    else
      .
    end
  )
' "$metadata_file" > "$metadata_file.tmp" && mv "$metadata_file.tmp" "$metadata_file"

echo "Updated contact email in $metadata_file to '$contact_email'"

