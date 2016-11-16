#!/usr/bin/env python

import sys, os
from bashrun import call
from parseargs import parseargs
import random
import string
import requests
import time

cert_cert_file = "/home/grid/client_test.crt"
cert_key_file = "/home/grid/client_test.key"
cert_server_file = "/etc/nginx/cert/server_test.crt"
protocol = "https"
nginx_adress = "localhost"
port = "8081"

args = parseargs(sys.argv)

job_path = args['job']
job_absolute_path = os.path.abspath(job_path)
job_name = job_path[job_path.rfind('/'):] if '/' in job_path else job_path
data_path = args['in'] if 'in' in args else None
def randomword(length):
	return ''.join(random.choice(string.lowercase) for i in range(length))
temp_tar = randomword(50)

id_job = random.randint(1,2**30)

call("mkdir " + temp_tar)
call("cp " + job_absolute_path + " " + temp_tar + "/" + job_name) 
call("(cd " + temp_tar + "; tar zcf arch.tar.gz *)")

request = requests.post(protocol + "://" + nginx_adress + ":" + str(port) + "/job/" + str(id_job), \
		verify=False, \
		cert=(cert_cert_file, cert_key_file), \
		files={'job': ('arch.tar.gz', open(temp_tar+'/arch.tar.gz', 'rb'), 'multipart/form-data', {'Expires': '0'})}  )

time.sleep(2)
call("rm -r " + temp_tar)

print(request.status_code)
print(request.text)
if request.status_code == 200:
	print("ok")
	exit(0)
else:
	print("pas ok")
	exit(-1)
