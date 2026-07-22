#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-what-if}"
LOCATION="${LOCATION:-francecentral}"
DEPLOYMENT_NAME="britedge-$(date -u +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="$(dirname "$0")/../infra/main.bicep"
PARAM_FILE="$(dirname "$0")/../infra/parameters.dev.bicepparam"

if [[ -z "${PG_ADMIN_PASSWORD:-}" ]]; then
  echo "ERROR: PG_ADMIN_PASSWORD env var not set." >&2
  echo "Set it in your shell (do NOT commit) then re-run." >&2
  exit 1
fi

echo "Mode:       $MODE"
echo "Region:     $LOCATION"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Template:   $TEMPLATE_FILE"
echo

case "$MODE" in
  what-if)
    az deployment sub what-if \
      --location "$LOCATION" \
      --template-file "$TEMPLATE_FILE" \
      --parameters "$PARAM_FILE" \
      --name "$DEPLOYMENT_NAME"
    ;;
  create)
    az deployment sub create \
      --location "$LOCATION" \
      --template-file "$TEMPLATE_FILE" \
      --parameters "$PARAM_FILE" \
      --name "$DEPLOYMENT_NAME"
    ;;
  *)
    echo "Unknown mode: $MODE (expected 'what-if' or 'create')" >&2
    exit 2
    ;;
esac
