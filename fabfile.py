from fabric.api import local, settings, abort, run, cd, env, hosts
from fabric.contrib.console import confirm

@hosts("sites@folky.fr")
def deploy_test():
	code_dir = '/home/sites/portfolio-test/portfolio'
	with cd(code_dir):
		run("git pull")
		run("../bin/python webapp.py collectstatic")

@hosts("sites@folky.fr")
def deploy():
	code_dir = '/home/sites/portfolio/portfolio'
	with cd(code_dir):
		run("git pull")
		run("../bin/python webapp.py collectstatic")