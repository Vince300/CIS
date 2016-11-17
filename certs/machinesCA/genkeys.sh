#!/bin/bash
for F in ensipc375 ensipc376 ensipc377; do
openssl genrsa -out ${F}.key 2048
openssl req -new -key ${F}.key -out ${F}.csr
openssl x509 -req -in ${F}.csr -CA machines.crt -CAkey machines.key -CAcreateserial -out ${F}.crt -days 180 -sha256
done
