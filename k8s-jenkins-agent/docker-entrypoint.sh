#!/usr/bin/env sh

if [ -f "/init" ]; then
    /init &
fi

exec /usr/local/bin/jenkins-agent "$@"
