#!/usr/bin/env bash
set -euo pipefail && [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

find /usr/share/icons -name '1cv8-uninstall*' -delete 2>/dev/null || true
find /usr/share/applications -name '1cv8-uninstall*' -delete 2>/dev/null || true

if ls /usr/share/applications/com._1c.installer.*.desktop 2>/dev/null; then
    sed -i 's|^\(Exec=/opt/1C/1CE/components/[^/][^/]*/1cedtstart\)\(/opt/1C/1CE/components/[^/][^/]*/1cedtstart\)|\1|' /usr/share/applications/com._1c.installer.*.desktop
    sed -i '/^Path=/d' /usr/share/applications/com._1c.installer.*.desktop
fi

if ls /usr/share/applications/1cv8*.desktop 2>/dev/null; then
    sed -i '/^Path=/d' /usr/share/applications/1cv8*.desktop

    for f in /usr/share/applications/1cv8*.desktop; do
        { grep -P '^Name(\[[^]]*\])?=[0-9]' "$f" || true; } | while IFS='=' read -r key val; do
            version=$(echo "$val" | grep -oP '^[0-9.]+')
            label=$(echo "$val" | sed 's/^[0-9.]*//; s/^\\n//')
            if echo "$key" | grep -q '\[ru'; then
                sed -i "s|^${key}=.*|${key}=1С $label $version|" "$f"
            else
                sed -i "s|^${key}=.*|${key}=1C $label $version|" "$f"
            fi
        done
    done
fi
