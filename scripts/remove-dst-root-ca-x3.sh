#!/usr/bin/env bash
set -euo pipefail && [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

FILE=/usr/share/ca-certificates/mozilla/DST_Root_CA_X3.crt
if [[ -f "$FILE" ]]; then
    rm -r $FILE
    update-ca-certificates
fi
