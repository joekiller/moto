#!/usr/bin/env bash

#adapted from https://serversforhackers.com/self-signed-ssl-certificates

KEYDIR=/home/mitmproxy/.mitmproxy
mkdir -p "$KEYDIR"

# Set the wildcarded domain
# we want to use
DOMAIN="amazonaws.com"

# A blank passphrase
PASSPHRASE=""

# Information needed for root key
SUBJ="
C=US
ST=Virginia
O=
commonName=Root Flask Local Certificate Authority
organizationalUnitName=
emailAddress=
"

# Generate the root key
openssl rsa -outform der -in "$KEYDIR"/mitmproxy-ca.pem -out "$KEYDIR"/private.key

# And a self-signed certificate
ln -s "$KEYDIR"/mitmproxy-ca.pem "$KEYDIR"/root.pem
openssl req -x509 -new -nodes -key "$KEYDIR"/root.key -sha256 -days 1024 -out \
	"$KEYDIR"/root.pem -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE

# Generate server and client keys
openssl genrsa -out "$KEYDIR"/server.key 2048

# Information needed for server certificate
SERVER_SUBJ="
C=US
ST=Virginia
O=
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

# Create certificate signing requests
openssl req -new -nodes -key "$KEYDIR"/server.key -sha256 -days 1024 -out \
	"$KEYDIR"/server.csr -subj "$(echo -n "$SERVER_SUBJ" | tr "\n" "/")" -passin pass:$PASSPHRASE
# Then sign them
for name in server; do
    openssl x509 -req -in "$KEYDIR/$name".csr -CA "$KEYDIR"/root.pem -CAkey "$KEYDIR"/root.key \
	    -CAcreateserial -out "$KEYDIR/$name".crt -days 500 -sha256
done

# Validate
for name in server; do
    openssl verify -CAfile "$KEYDIR"/root.pem "$KEYDIR/$name".crt
done
