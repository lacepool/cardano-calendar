#!/bin/bash -e

PATH=$PATH:/usr/local/bin

cd /rails || exit

echo "CRON: ${@}" >/proc/1/fd/1 2>/proc/1/fd/2

exec "${@}" >/proc/1/fd/1 2>/proc/1/fd/2
