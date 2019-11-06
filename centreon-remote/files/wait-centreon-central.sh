#!/bin/sh
# wait-centreon-central.sh

set -e

host="$1"
shift
cmd="$@"

until nc -z $host 5669; do
  >&2 echo "Centreon Central is unavailable - sleeping"
  sleep 5
done

>&2 echo "Centreon Central is up - executing command"
exec $cmd

