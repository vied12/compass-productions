# import sys, os
# sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
activate_this = os.path.dirname(os.path.realpath(__file__))
execfile(activate_this, dict(__file__=activate_this))
import webapp as application