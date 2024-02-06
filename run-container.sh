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

if $CM ps -a | grep dsm-kmip-server >/dev/null 2>&1; then
    echo "=== Cleaning up old container"
    $CM stop dsm-kmip-server >/dev/null
    $CM rm dsm-kmip-server >/dev/null
fi

echo "=== Starting new container"
$CM run -d --name dsm-kmip-server -p 5696:5696 \
    --mount type=bind,source="$WORKDIR"/state,target=/var/lib/state \
    --mount type=bind,source="$WORKDIR"/certs,target=/var/lib/certs \
    dsm-kmip-server:latest
