 	import sys
# virtualenv
activate_this = "/home/django-projects/portfolio/bin/activate_this.py"
execfile(activate_this, dict(__file__=activate_this))

sys.path.insert(0, "/home/django-projects/portfolio/portfolio")

from webapp import app as application
