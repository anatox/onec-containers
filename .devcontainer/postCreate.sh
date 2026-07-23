#!/bin/bash
set -euo pipefail

if [ ! -f .envrc ]; then
    cp .envrc.example .envrc
    echo "Created .envrc from .envrc.example — fill in 1C credentials"
fi

docker buildx version

./bake --version >/dev/null

echo ""
echo "Devcontainer ready."
echo "Build leaf target:    ./bake build oscript"
echo "Build server chain:   ./bake build server"
echo "Build full graph:     ./bake build default"
echo ""
