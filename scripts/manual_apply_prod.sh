#!/usr/bin/env bash
set -e

# Путь к overlay prod
OVERLAY_DIR="$(dirname "$0")/../cluster/environments/prod"

echo "Применяем prod overlay из $OVERLAY_DIR ..."
kubectl apply -k "$OVERLAY_DIR"
