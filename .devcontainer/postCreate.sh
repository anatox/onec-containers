#!/bin/bash
set -euo pipefail

if [ ! -f .envrc ]; then
    cp .envrc.example .envrc
    echo "Created .envrc from .envrc.example — fill in 1C credentials"
fi

docker buildx version

echo ""
echo "Devcontainer ready."
echo "Build leaf target:    scripts/bake.py oscript"
echo "Build server chain:   scripts/bake.py server"
echo "Build full graph:     scripts/bake.py default"
echo ""
