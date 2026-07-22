#!/usr/bin/env bash

set -euo pipefail

RG_NAME="${1:-britedge-dev-rg}"

echo "About to delete resource group: $RG_NAME"
echo "This will destroy all resources inside it (irreversible)."
read -rp "Type the RG name to confirm: " CONFIRM

if [[ "$CONFIRM" != "$RG_NAME" ]]; then
  echo "Aborted: name did not match."
  exit 1
fi

az group delete --name "$RG_NAME" --yes --no-wait
echo "Delete request sent (running async). Track with: az group show -n $RG_NAME"
