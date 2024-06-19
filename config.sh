# After any change in this configuration file you will need to rebuild the
# container and remove existing certificate(s) and key(s). This will most
# likely break Encryption Key Vault in DSM, and you will have to reinitialize
# it. Be sure to keep your volume recovery keys is safe place, since you will
# need them if you want to reinitialize KMIP server.

################################################################################
# Following configuration options must be reviewed and set correctly before
# starting KMIP server for the first time and storing your Encryption Key Vault
# in it. It will be much harder to change any of these values when you are
# already running KMIP.
################################################################################

# RSA key size and lifetime configuration
CA_KEY_SIZE=2048 # (bits, 2048 or 4096 is recommended)
CA_LIFETIME=3560 # (days)
CLIENT_KEY_SIZE=2048 # (bits, 2048 or 4096 is recommended)
CLIENT_CERT_LIFETIME=1095 # (days)
SERVER_KEY_SIZE=2048 # (bits, 2048 or 4096 is recommended)
SERVER_CERT_LIFETIME=1095 # (days)

# Server and client address configuration. This will be encoded in certificates,
# so it will not be possible to change it without recreating certificates and
# losing KMIP data.
# 
# If you have local DNS in your environment, syntax is following:
# SSL_SERVER_NAME=DNS:<fully qualified hostname of this KMIP server>
# SSL_CLIENT_NAME=DNS:<fully qualified hostname of Synology NAS>
#
# Otherwise, you can configure static IP addresses:
# SSL_SERVER_NAME=IP:<IP address of this KMIP server>
# SSL_CLIENT_NAME=IP:<IP address of Synology NAS>
#
SSL_SERVER_NAME="IP:192.168.255.5"
SSL_CLIENT_NAME="IP:192.168.255.10"

################################################################################
# Following configuration options do not really matter but it is nice to set
# them
################################################################################

# Common names for CA, server and client certificates
SSL_COMMON_NAME_CA="Private KMIP CA"
SSL_COMMON_NAME_SERVER="Private KMIP Server"
SSL_COMMON_NAME_CLIENT="Private KMIP Client"

# Country name for CA, server and client certificates. Set to two letter
# country code, for example US or DE
SSL_COUNTRY_NAME="DE"

# State or province name for CA, server and client certificates
SSL_STATE_OR_PROVINCE="Berlin"

# Locality (city/town) name for CA, server and client certificates
SSL_LOCALITY="Berlin"

# Organization name for CA, server and client certificates
SSL_ORGANIZATION="Private SAN"

# Organizational unit name for CA, server and client certificates
SSL_ORGANIZATIONAL_UNIT="PKI"
