#!/usr/bin/env bash
set -euo pipefail && [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

jdk_path=$(find /opt/1C/1CE/components -maxdepth 1 -name 'axiom-jdk-full-*' -type d | sort -V | tail -1)
if [ -n "$jdk_path" ]; then
  ln -sf "$jdk_path" /opt/1C/1CE/components/jdk-current
else
  jdk_path=$(find /usr/lib/jvm -maxdepth 1 -name 'bellsoft-java*-amd64' -type d | sort -V | tail -1)
  if [ -n "$jdk_path" ]; then
    ln -sf "$jdk_path" /opt/1C/1CE/components/jdk-current
  fi
fi

find /opt/1C/1CE -name 1cedtstart -type f -exec ln -sf {} /opt/1C/1CE/components/1c-edt-start-current \;
find /opt/1C/1CE -name 1cedtcli -type f -exec ln -sf {} /opt/1C/1CE/components/1c-edt-current \;
find /opt/1C/1CE -name ring -type f -exec ln -sf {} /usr/local/bin/ring \;
