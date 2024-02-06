#!/bin/sh

set -e

if docker -v >/dev/null 2>&1; then 
    CM=docker
elif podman -v >/dev/null 2>&1; then
    CM=podman
else
    echo "Container manager not installed. Please install docker or podman."
    exit 1
fi

WORKDIR=$(cd -- "$(dirname -- "$0")" && pwd)

$CM build -t dsm-kmip-server:latest "$WORKDIR"
