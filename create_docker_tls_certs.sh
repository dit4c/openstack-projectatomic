#!/bin/bash

# Based on Sven's rundown here:
# https://docs.docker.com/engine/articles/https/

HOST=$(hostname)

# Generate CA key/cert
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 3650 -subj "/CN=$HOST" \
  -key ca-key.pem -sha256 -out ca.pem
chmod 0400 ca-key.pem
chmod 0444 ca.pem

# Generate server key/cert
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
echo subjectAltName = IP:172.18.0.1,IP:127.0.0.1 > extfile.cnf
openssl x509 -req -days 3650 -sha256 -in server.csr \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem -extfile extfile.cnf
chmod 0400 server-key.pem
chmod 0444 server-cert.pem

# Generate client key/cert
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
openssl x509 -req -days 3650 -sha256 -in client.csr \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out cert.pem -extfile extfile.cnf
chmod 0444 key.pem
chmod 0444 cert.pem

# Move client files to the right directory
mkdir -p $HOME/.docker
mv key.pem cert.pem $HOME/.docker
cp ca.pem $HOME/.docker
# Move server files to /etc/docker
sudo chown root:root ca-key.pem ca.pem ca.srl server-key.pem server-cert.pem
sudo mv ca-key.pem ca.pem ca.srl server-key.pem server-cert.pem /etc/docker
