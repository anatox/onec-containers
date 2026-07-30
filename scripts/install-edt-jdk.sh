#!/usr/bin/env bash
set -euo pipefail; [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

edt_version="${1:-}"

if [ -z "$edt_version" ]; then
  echo "ОШИБКА: не указаны обязательные аргументы: <версия>" >&2
  exit 1
fi

EDT_MAJOR=$(echo "$edt_version" | cut -d'.' -f1)

if ! [[ "$EDT_MAJOR" =~ ^[0-9]+$ ]]; then
  echo "ОШИБКА: ожидается числовое значение мажорной версии. Фактическое значение: '$edt_version'" >&2
  exit 1
fi

if [ "$EDT_MAJOR" -gt 2024 ]; then
  exit 0
fi

apt-get update -qq

DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
  wget \
  apt-transport-https \
  gpg

mkdir -p /etc/apt/keyrings
wget -q -O - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | gpg --dearmor | tee /etc/apt/keyrings/GPG-KEY-bellsoft.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/GPG-KEY-bellsoft.gpg] https://apt.bell-sw.com/ stable main" | tee /etc/apt/sources.list.d/bellsoft.list

if [ "$EDT_MAJOR" -le 2023 ]; then
  JDK_PACKAGE="bellsoft-java11"
else
  JDK_PACKAGE="bellsoft-java17"
fi

apt-get update -qq

DEBIAN_FRONTEND=noninteractive apt-get install -y -o=Dpkg::Use-Pty=0 --no-install-recommends \
  "${JDK_PACKAGE}"
