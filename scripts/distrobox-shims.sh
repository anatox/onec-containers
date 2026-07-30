#!/usr/bin/env sh
set -eu; [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

if [ ! -x /usr/bin/distrobox-host-exec ]; then
    echo "ОШИБКА: /usr/bin/distrobox-host-exec не найден или не является исполняемым" >&2
    exit 1
fi

[ ! -e /usr/bin/sh ] && ln -fs /bin/sh /usr/bin/sh
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree
ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/transactional-update
