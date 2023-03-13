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

if $CM ps -a | grep dsm-kmip-server >/dev/null 2>&1; then
    echo "=== Cleaning up old container"
    $CM stop dsm-kmip-server >/dev/null
    $CM rm dsm-kmip-server >/dev/null
fi

echo "=== Starting new container"
$CM run -d --name dsm-kmip-server -p 5696:5696 \
    --restart=unless-stopped \
    --mount type=bind,source=$WORKDIR/state,target=/var/lib/state \
    --mount type=bind,source=$WORKDIR/certs,target=/var/lib/certs \
    dsm-kmip-server:latest
