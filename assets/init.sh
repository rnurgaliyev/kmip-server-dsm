#!/bin/sh

set -e

source /etc/pykmip/config.sh

mkdir -p /var/lib/certs

if [ ! -f /var/lib/certs/ca.key ]; then
    echo "=== Generating private CA RSA key"
    openssl genrsa -out /var/lib/certs/ca.key $CA_KEY_SIZE
fi

if [ ! -f /var/lib/certs/ca.crt ]; then
    echo "=== Generating private CA certificate"
    openssl req -nodes -x509 -days $CA_LIFETIME \
        -key /var/lib/certs/ca.key \
        -out /var/lib/certs/ca.crt \
        -subj "/C=$SSL_COUNTRY_NAME/ST=$SSL_STATE_OR_PROVINCE/L=$SSL_LOCALITY/O=$SSL_ORGANIZATION/OU=$SSL_ORGANIZATIONAL_UNIT/CN=$SSL_COMMON_NAME_CA"
fi

if [ ! -f /var/lib/certs/server.key ]; then
    echo "=== Generating server RSA key"
    openssl genrsa -out /var/lib/certs/server.key $SERVER_KEY_SIZE
fi

if [ ! -f /var/lib/certs/server.crt ]; then
    echo "=== Generating server certificate"
    openssl req -key /var/lib/certs/server.key -new \
        -out /var/lib/certs/server.csr \
        -subj "/C=$SSL_COUNTRY_NAME/ST=$SSL_STATE_OR_PROVINCE/L=$SSL_LOCALITY/O=$SSL_ORGANIZATION/OU=$SSL_ORGANIZATIONAL_UNIT/CN=$SSL_COMMON_NAME_SERVER" \
        -addext "subjectAltName = $SSL_SERVER_NAME" \
        -addext "extendedKeyUsage = serverAuth, clientAuth"
    openssl x509 -req -CA /var/lib/certs/ca.crt \
        -CAkey /var/lib/certs/ca.key \
        -in /var/lib/certs/server.csr \
        -out /var/lib/certs/server.crt \
        -days $SERVER_CERT_LIFETIME -CAcreateserial -copy_extensions copy
fi

if [ ! -f /var/lib/certs/client.key ]; then
    echo "=== Generating client RSA key"
    openssl genrsa -out /var/lib/certs/client.key $CLIENT_KEY_SIZE
fi

if [ ! -f /var/lib/certs/client.crt ]; then
    echo "=== Generating client certificate"
    openssl req -key /var/lib/certs/client.key -new \
        -out /var/lib/certs/client.csr \
        -subj "/C=$SSL_COUNTRY_NAME/ST=$SSL_STATE_OR_PROVINCE/L=$SSL_LOCALITY/O=$SSL_ORGANIZATION/OU=$SSL_ORGANIZATIONAL_UNIT/CN=$SSL_COMMON_NAME_CLIENT" \
        -addext "subjectAltName = $SSL_CLIENT_NAME" \
        -addext "extendedKeyUsage = serverAuth, clientAuth"
    openssl x509 -req -CA /var/lib/certs/ca.crt \
        -CAkey /var/lib/certs/ca.key \
        -in /var/lib/certs/client.csr \
        -out /var/lib/certs/client.crt \
        -days $CLIENT_CERT_LIFETIME -CAcreateserial -copy_extensions copy
fi

# Ensure pykmip-server logs are directed to stdout
pykmip-server -l /dev/stdout