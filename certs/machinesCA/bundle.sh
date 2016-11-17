#!/bin/bash
mkdir -p bundled
for F in ensipc*.crt; do
    cat $F machines.crt >bundled/$F
done
