#!/bin/sh

set -e

if podman -v >/dev/null 2>&1; then 
    CM=podman
elif docker -v >/dev/null 2>&1; then
    CM=docker
else
    echo "Container manager not installed. Please install podman or docker."
    exit 1
fi

WORKDIR=$(cd -- "$(dirname -- "$0")" && pwd)

$CM build -t dsm-kmip-server:latest "$WORKDIR"
