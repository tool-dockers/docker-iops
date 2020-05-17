#!/usr/bin/dumb-init /bin/sh

set -e

if [ "${1:0:1}" = '-' ]; then
    set -- fio "$@"
fi

if [ "$1" = 'fio' -o "$1" = 'ioping' ]; then
  if [ "$(stat -c %u /iops/config)" != "$(id -u iops)" ]; then
    chown iops:iops /iops/config
  fi
  if [ "$(stat -c %u /iops/data)" != "$(id -u iops)" ]; then
    chown iops:iops /iops/data
  fi
fi

if [ "$1" = 'fio' ]; then
  set -- su-exec iops:iops "$@"
elif [ "$1" = 'ioping' ]; then
  set -- su-exec iops:iops "$@"
fi

exec "$@"
