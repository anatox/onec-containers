#!/usr/bin/env bash
set -euo pipefail; [ "${DEBUG_TRACE:-0}" -ne 0 ] && set -x

mapfile -t platform_paths < <(find /opt/1cv8/ -type f \( -name "1cv8c" -o -name "1cv8" -o -name "ragent" -o -name "crserver" \) -exec dirname {} \; 2>/dev/null | sort -u)

unique_paths=$(printf '%s\n' "${platform_paths[@]}" | sort -u | wc -l)
if [ "${#platform_paths[@]}" -eq 0 ]; then
    echo "ОШИБКА: бинарные файлы платформы 1С не найдены. Вероятно, установка завершилась неудачно." >&2
    exit 1
fi
if [ "$unique_paths" -ne 1 ]; then
    echo "ОШИБКА: найдено несколько разных каталогов платформы 1С: ${platform_paths[*]}" >&2
    exit 1
fi

platform_path="${platform_paths[0]}"

mkdir -p /opt/1cv8
ln -sfn "$platform_path" /opt/1cv8/current
