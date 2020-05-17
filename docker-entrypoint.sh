#!/usr/bin/dumb-init /bin/sh

set -e

if [ "${1:0:1}" = '-' ]; then
    set -- curl "$@"
fi

if [ "$1" = 'curl' ]; then
  if [ -f /${USER}/.curlrc && "$(stat -c %u /${USER}/.curlrc)" != "$(id -u ${USER})" ]; then
    chown ${GROUP}:${USER} /${USER}/.curlrc
  fi
fi

if [ "$1" = 'curl' ]; then
  set -- su-exec ${GROUP}:${USER} "$@"
fi

exec "$@"
