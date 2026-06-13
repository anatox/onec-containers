#!/bin/bash
set -e

platform_path=$(find / -type f -name "1cv8c" -exec dirname {} \; -or -type f -name "1cv8" -exec dirname {} \; -or -type f -name "ragent" -exec dirname {} \; -or -type f -name "crserver" -exec dirname {} \; | uniq)

if [ -z "$platform_path" ]; then
    echo "ERROR: 1C binaries not found (1cv8/ragent/crserver). Installer likely failed."
    exit 1
fi

mkdir -p /opt/1cv8 \
    && ln -s "$platform_path" /opt/1cv8/current
