# Lancer Job

#####################################################
#
#   README
#
#
#   - Ajouter un argument au script : to doc
#
#
#
#



import sys
from worker import Worker
from remotesite import RemoteSite
from bashrun import call
from parseargs import parseargs
import random

""" 
	PARAMETRES GLOBAUX
"""


remote_sites = {
	RemoteSite('localhost') # Je sais... chut
	# Add other sites here
} 

# Workers locaux
local_workers = [
	Worker('ensipc375'),
	Worker('ensipc377')
]

# Nombre d'essais de recherche de worker avant notification d'échec à l'utilisateur
try_worker_limit = 15

"""
	FIN PARAMETRES GLOBAUX
"""


args = parseargs(sys.argv)

print(args)
if not args['local']:
	print("lancerjob only runs in local mode yet (--local)")
	exit(-1)

job_sent = False
nb_try = 0
while not job_sent or nb_try > try_worker_limit:
	nb_try += 1
	if args['local']:
		job_sent = True
		random_worker = random.choice(local_workers)
		random_worker.launch_job()
	else:
		pass


