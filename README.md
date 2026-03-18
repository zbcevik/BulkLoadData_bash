
# Borealis Bulk Dataset Uploader

A fully guided beginner-friendly reference for using `bulkupload_bash.sh` to upload multiple datasets into Borealis Dataverse.

This Bash script does three main actions per dataset folder:
1. Ensures each dataset JSON includes a contact email entry (`datasetContactEmail`).
2. Creates a dataset in your Dataverse using dataset metadata (without the `files` block).
3. Uploads `files.zip` for that dataset using Dataverse SWORDv2 upload API.

---

## What this repository contains

- `bulkupload_bash.sh`: main script that processes dataset folders in `Datasets/`.
- `Datasets/`: each subfolder is one dataset package.

### Expected dataset directory layout (keep this figure):

```
Datasets/
  dataset1/
    metadata.json   # dataset metadata with citation + author + fields, etc.
    files.zip       # zipped payload of files to attach to dataset
  dataset2/
    metadata.json
    files.zip
  dataset3/
    metadata.json
    files.zip

```

- `metadata.json` is used for dataset creation via API.
- `files.zip` is uploaded after dataset creation.

---

## Prerequisites (very beginner-friendly)

1. Linux/MacOS terminal access.
2. Bash shell (default on most systems).
3. Install `jq` and `curl`.

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y jq curl
```

macOS (Homebrew):

```bash
brew install jq curl
```

Verify both are installed with:

```bash
jq --version
curl --version
```

---

## Setup (best practice for new users)

1. Clone this project:

```bash
git clone https://github.com/zbcevik/BulkLoadData_bash.git
cd BulkLoadData_bash
```

2. Put your datasets under `Datasets/`:

- One folder per dataset (e.g. `Datasets/dataset1/`).
- Required files in each folder: `metadata.json`, `files.zip`.

3. Open `bulkupload_bash.sh` with a text editor and set your API info:

```bash
API_TOKEN="YOUR_API_TOKEN"
HOSTNAME="https://demo.borealisdata.ca"               # or your Borealis host
DATAVERSE_ALIAS="YOUR_DATAVERSE_ALIAS"
DIRECTORY="Datasets"                                  # where dataset folders live
WAIT=0
CONTACT_EMAIL="your.contact@example.com"              # used for dataset contact field
```

4. Make sure `bulkupload_bash.sh` is executable:

```bash
chmod +x bulkupload_bash.sh
```

---

## Run the script

```bash
./bulkupload_bash.sh
```

What happens during run:
- Script loops `for datasetDir in "$DIRECTORY"/*`.
- Calls `add_dataset_contact_email` to add or reuse `datasetContactEmail` in metadata.
- Sends `POST /api/dataverses/$DATAVERSE_ALIAS/datasets/?key=$API_TOKEN` with metadata minus `datasetVersion.files`.
- Reads the response, extracts `DOI`.
- If DOI exists, uploads `files.zip` to `/dvn/api/data-deposit/v1.1/swordv2/edit-media/study/$DOI`.
- Logs status for each dataset and continues next dataset.

---

## Post-run verification

- If upload is successful, you should see output lines like:
  - `Response: ...` (API JSON)
  - `Extracted DOI: doi:10...`
  - `Done with Datasets/dataset1`

- Verify on the Dataverse UI using the DOI.

---

## Troubleshooting

- `❌ Metadata file not found`: confirm `metadata.json` exists in each dataset folder.
- `❌ No DOI found`: dataset creation failed (check API token, hostname, metadata validity).
- `curl: (6) Could not resolve host`: wrong `HOSTNAME` or network issues.

---

## Notes

- `metadata.json` must be valid JSON and have the `datasetVersion` block the script expects.
- The script removes `datasetVersion.files` before dataset creation to avoid metadata upload conflict.

---

## Reference

Original inspiration:
https://github.com/kaitlinnewson/dataverse-tools/blob/master/bulkloaddata.sh

