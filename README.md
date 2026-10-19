
# Borealis/Dataverse Bulk Dataset Uploader

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)

A Bash tool for creating multiple datasets and uploading their files into a specified Borealis/Dataverse collection.

This Bash script does three main actions per dataset folder:
1. Adds the configured contact email to existing `datasetContact` entries that are missing `datasetContactEmail`. Existing email values are preserved.
2. Creates a dataset using `metadata.json`, excluding `datasetVersion.files` from the creation request.
3. Uploads `files.zip` to the created dataset using the Dataverse SWORDv2 API.

The metadata must already contain the expected `datasetVersion.metadataBlocks.citation.fields` structure and a `datasetContact` entry. The script does not create a missing contact entry. It modifies `metadata.json` in place, so back up your dataset folders before running it.

> [!CAUTION]
> This script immediately creates datasets and uploads files.
> It has no preview mode. Test with one dataset on
> https://demo.borealisdata.ca first. Running it again can create duplicates.
---

## What this repository contains

- `bulkupload.sh`: main script that processes dataset folders in the directory set in `config.sh`.
- `config.sh`: API settings and the location of your dataset folders.
- `ContactInfo.sh`: optional helper for adding a contact email to a metadata file.
- `Datasets/`: each subfolder is one dataset package.

### Expected dataset directory layout:

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

The included dataset folders are mock fixtures. Each archive contains a small synthetic
`ExcelExample_Corr_Reg.tab` file, and each metadata file describes that matching payload.

---

## Prerequisites 

- A Dataverse API token with permission to create datasets and upload files in the target collection.
- The target collection’s alias.
- A server supporting the Dataverse dataset-creation API and SWORDv2 upload endpoint.
- Linux/MacOS terminal access.
- Bash shell (default on most systems).
- Install `jq` and `curl`.

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

## Setup 

1. Clone this project:

```bash
git clone https://github.com/zbcevik/BulkLoadData_bash.git
cd BulkLoadData_bash
```

Alternatively, open the repository on GitHub, select **Code** > **Download ZIP**, extract the ZIP file, and open a terminal in the extracted project folder.

2. Put your datasets under `Datasets/`:

- One folder per dataset (e.g. `Datasets/dataset1/`).
- Required files in each folder: `metadata.json`, `files.zip`.

3. Open `config.sh` with a text editor and set your API info. Set `DIRECTORY` to the full path of the folder containing your dataset folders. For example, if the project is in your home folder:

```bash
export API_TOKEN="YOUR_API_TOKEN"
export HOSTNAME="https://demo.borealisdata.ca"        # or your Borealis host
export DATAVERSE_ALIAS="YOUR_DATAVERSE_ALIAS"
export DIRECTORY="$HOME/BulkLoadData_bash/Datasets"   # change this if the project is elsewhere
export CONTACT_EMAIL="your.contact@example.com"       # used for dataset contact field
```

The uploader automatically loads `config.sh` from the same folder as `bulkupload.sh`.

4. From the project folder, run the script with Bash:

```bash
bash ./bulkupload.sh
```

The script creates and uploads a dataset for every subfolder in `DIRECTORY`. This is a live upload, not a preview. Use a test Dataverse or a directory containing only one dataset folder for your first run; running it again can create duplicate datasets.

What happens during run:
- Script loops `for datasetDir in "$DIRECTORY"/*`.
- Calls `add_dataset_contact_email` to add a missing email to existing dataset-contact entries in `metadata.json`. Existing email values are preserved.
- Sends `POST /api/dataverses/$DATAVERSE_ALIAS/datasets/?key=$API_TOKEN` with metadata minus `datasetVersion.files`.
- Reads the response, extracts `DOI`.
- If DOI exists, uploads `files.zip` to `/dvn/api/data-deposit/v1.1/swordv2/edit-media/study/$DOI`.
- Logs status for each dataset and continues next dataset.

---

## Post-run verification

Open each created dataset in the Dataverse UI using its DOI and confirm:

- It belongs to the intended collection.
- Its metadata is correct.
- All expected files are attached.

---

## Errors and recovery

- Dataset creation and file upload are separate operations. If creation succeeds but file upload fails, the dataset may already exist. Inspect that dataset before rerunning the script, because rerunning can create a duplicate. The script does not automatically roll back created datasets.

---
## Troubleshooting

- `❌ Metadata file not found`: confirm `DIRECTORY` points to the parent folder containing the dataset folders, and that each folder contains `metadata.json`. Use a full path, such as `"$HOME/Downloads/Datasets"`.
- `❌ No DOI found`: dataset creation failed (check API token, hostname, metadata validity).
- `curl: (6) Could not resolve host`: wrong `HOSTNAME` or network issues.
- Missing or unreadable `files.zip`: confirm the archive exists and is readable in the dataset folder. If a dataset was already created, inspect it before rerunning to avoid duplicates.

---

## Notes

- `metadata.json` must be valid JSON and have the `datasetVersion` block the script expects.
- The script removes `datasetVersion.files` before dataset creation to avoid metadata upload conflict.

---

## Reference

Original inspiration:
https://github.com/kaitlinnewson/dataverse-tools/blob/master/bulkloaddata.sh

