#!/usr/bin/env bash
set -euxo pipefail

platform_path=$(find /opt/1cv8/ -type f \( -name "1cv8c" -o -name "1cv8" -o -name "ragent" -o -name "crserver" \) -exec dirname {} \; 2>/dev/null | uniq)

if [ -z "$platform_path" ]; then
    echo "ERROR: 1C binaries not found (1cv8/ragent/crserver). Installer likely failed."
    exit 1
fi

mkdir -p /opt/1cv8
ln -s "$platform_path" /opt/1cv8/current
