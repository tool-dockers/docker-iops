#!/usr/bin/dumb-init /bin/sh

set -e

if [ "${1:0:1}" = '-' ]; then
    set -- fio "$@"
fi

if [ "$1" = 'fio' ]; then
  set -- su-exec iops:iops "$@"
elif [ "$1" = 'ioping' ]; then
  set -- su-exec iops:iops "$@"
fi

exec "$@"
