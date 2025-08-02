#!/bin/sh

pcr15_hash=$1

echo "Checking PCR 15 value"
if [[ $(systemd-analyze pcrs 15 --json=short | jq -r ".[0].sha256") != "$pcr15_hash" ]] ; then
    echo "PCR 15 check failed"
    exit 1
else
    echo "PCR 15 check succeeded"
fi
