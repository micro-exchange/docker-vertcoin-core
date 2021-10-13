#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for vertcoind"

  set -- vertcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "vertcoind" ]; then
  mkdir -p "$VERTCOIN_DATA"
  chmod 700 "$VERTCOIN_DATA"
  chown -R vertcoin "$VERTCOIN_DATA"

  echo "$0: setting data directory to $VERTCOIN_DATA"

  set -- "$@" -datadir="$VERTCOIN_DATA"
fi

if [ "$1" = "vertcoind" ] || [ "$1" = "vertcoin-cli" ]; then
  echo
  exec su-exec vertcoin "$@"
fi

echo
exec "$@"