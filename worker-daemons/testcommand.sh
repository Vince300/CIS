#!/bin/bash
curl -F "job=@test.tar.gz" -E b.pem --key b.key --cacert ca.pem "https://A:8443/job/1"
