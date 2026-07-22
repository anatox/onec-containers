#!/usr/bin/env bash
set -euo pipefail

# В некоторых версиях EDT отсутствует бинарник nginx, хотя его наличие ожидается — подкладываем системный
for nginx_dir in /opt/1C/1CE/components/1c-edt-*/plugins/*/binaries/nginx/; do
    [ -d "$nginx_dir" ] || continue
    [ -e "${nginx_dir}nginx" ] && continue

    if ! command -v nginx >/dev/null 2>&1; then
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends nginx
    fi

    ln -sf "$(which nginx)" "${nginx_dir}nginx"
done
