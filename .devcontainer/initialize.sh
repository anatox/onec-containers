#!/bin/sh
set -eu

if [ ! -f .devcontainer/local.compose.yaml ]; then
    echo 'services:' > .devcontainer/local.compose.yaml
fi
