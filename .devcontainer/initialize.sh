#!/usr/bin/env sh
set -eu

if [ ! -f .devcontainer/local.compose.yaml ]; then
    touch .devcontainer/local.compose.yaml
fi
