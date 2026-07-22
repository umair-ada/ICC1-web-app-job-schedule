#!/usr/bin/env bash

set -euo pipefail

RG_NAME="${RG_NAME:-britedge-dev-rg}"
APP_NAME="${APP_NAME:-britedge-app}"

ACR_NAME=$(az resource list \
  --resource-group "$RG_NAME" \
  --resource-type Microsoft.ContainerRegistry/registries \
  --query "[0].name" -o tsv)

if [[ -z "$ACR_NAME" ]]; then
  echo "ERROR: no ACR found in $RG_NAME. Has Phase 1 deploy completed?" >&2
  exit 1
fi

TAG="${1:-v$(git rev-parse --short HEAD 2>/dev/null || echo 'manual')}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "ACR:        $ACR_NAME"
echo "Tag:        $TAG"
echo "Building from: $REPO_ROOT"
echo

az acr login --name "$ACR_NAME"

docker buildx build \
  --platform linux/amd64 \
  -t "$ACR_NAME.azurecr.io/britedge:$TAG" \
  -t "$ACR_NAME.azurecr.io/britedge:latest" \
  --push \
  "$REPO_ROOT"

az containerapp registry set \
  --name "$APP_NAME" \
  --resource-group "$RG_NAME" \
  --server "$ACR_NAME.azurecr.io" \
  --identity system > /dev/null

echo
echo "Flipping ingress target port to 8080 (Flask/gunicorn)..."
az containerapp ingress update \
  --name "$APP_NAME" \
  --resource-group "$RG_NAME" \
  --target-port 8080 \
  --type external > /dev/null

echo "Rolling out to Container App with liveness+readiness on /healthz + PORT env..."
az containerapp update \
  --name "$APP_NAME" \
  --resource-group "$RG_NAME" \
  --image "$ACR_NAME.azurecr.io/britedge:$TAG" \
  --set-env-vars PORT=8080 \
  --query "properties.configuration.ingress.fqdn" -o tsv \
  | tee /tmp/britedge-fqdn

echo
FQDN=$(cat /tmp/britedge-fqdn)
echo "Live at: https://$FQDN"
echo "Smoke test: curl -sSf https://$FQDN/healthz"
