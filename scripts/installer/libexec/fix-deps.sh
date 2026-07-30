#!/usr/bin/env bash
set -euo pipefail; [ "${DEBUG_TRACE:-0}" -ne 0 ] && set -x

# Удаление поставляемых файлов GCC/STL (конфликт версий GLIBCXX/GCC на Ubuntu 26.04+)
[ "${DEBUG_TRACE:-0}" -ne 0 ] && DEBUG_ARGS=(-print) || DEBUG_ARGS=()
find /opt/1cv8 \( -name "libgcc_s.so*" -o -name "libstdc++.so*" \) "${DEBUG_ARGS[@]}" -delete
