
for datasetDir in "$DIRECTORY"/* ; do
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
