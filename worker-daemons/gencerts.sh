#!/bin/bash

openssl genrsa -out ca.key 2048
openssl genrsa -out a.key 2048
openssl genrsa -out b.key 2048

openssl req -x509 -new -nodes -key ca.key -sha256 -days 1024 -out ca.pem

openssl req -new -key a.key -out a.csr
openssl req -new -key b.key -out b.csr

openssl x509 -req -in a.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out a.crt -days 365 -sha256
openssl x509 -req -in b.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out b.crt -days 365 -sha256
