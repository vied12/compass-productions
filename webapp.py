#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 30-Jun-2012
# Last mod : 30-Jun-2012
# -----------------------------------------------------------------------------

from flask import Flask, render_template, request
from flaskext.babel import Babel
import os, sys, sources.preprocessing as preprocessing

app = Flask(__name__)
app.config.from_pyfile("settings.cfg")

@app.route('/')
def index():
	return render_template('home.html')

if __name__ == '__main__':
	if len(sys.argv) > 1 and sys.argv[1] == "collectstatic":
		preprocessing._collect_static(app)
	else:
		babel = Babel(app) # i18n
		# render ccss, coffeescript and shpaml in 'templates' and 'static' dirs
		preprocessing.preprocess(app, request) 
		# run application
		app.run()
# EOF

