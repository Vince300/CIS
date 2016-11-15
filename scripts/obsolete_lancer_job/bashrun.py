import subprocess


def call(command):
	subprocess.call(command, shell=True)
