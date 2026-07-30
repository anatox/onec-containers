#!/usr/bin/env sh

if [ -f "/init" ]; then
    /init &
fi

exec "$@"
