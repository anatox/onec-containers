#!/usr/bin/env bash
set -euo pipefail; [ "${DEBUG_TRACE:-0}" -ne 0 ] && set -x

EDT_VERSION=${1:-}
if [ -z "$EDT_VERSION" ]; then
    echo "ОШИБКА: не указаны обязательные аргументы: <версия>" >&2
    exit 1
fi

INSTALLER_FILENAME='1ce-installer-cli'
INSTALLER="${DOWNLOADS_ROOT:?}/DevelopmentTools10/${EDT_VERSION}/${INSTALLER_FILENAME}"

if [ ! -f "$INSTALLER" ]; then
    echo "ОШИБКА: Не найден файл установки $INSTALLER" >&2
    exit 1
fi

chmod +x "$INSTALLER"

"$INSTALLER" install all --ignore-hardware-checks --ignore-signature-warnings 2>&1 |
    sed -u '/^\s*[0-9]\{1,3\},[0-9]\{1,2\}% .*$/d'
