#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 30-Jun-2012
# Last mod : 30-Jun-2012
# -----------------------------------------------------------------------------

from flask import Flask, render_template
import os, sys, sources.preprocessing as preprocessing

app = Flask(__name__)

@app.route('/')
def index():
	return render_template('home.html')

if __name__ == '__main__':
	#os.path.join(app.root_path, 'lib')
	app.config['STATIC_DIR'] 	= os.path.join(app.root_path, 'static')
	app.config['LIB_DIR'] 		= os.path.join(app.root_path, 'lib')

	if len(sys.argv) > 1 and sys.argv[1] == "collectstatic":
		preprocessing._collect_static(app)
	else:
		app.config.from_pyfile("settings.cfg")		
		app.config['JS_DIR'] 		= os.path.join(app.config['STATIC_DIR'], 'js')
		app.config['CSS_DIR'] 		= os.path.join(app.config['STATIC_DIR'], 'css')
		app.config['IMAGES_DIR'] 	= os.path.join(app.config['STATIC_DIR'], 'images')		
		app.config['TEMPLATE_DIR'] 	= os.path.join(app.root_path, app.template_folder)

		preprocessing.preprocess(app) # render ccss, coffeescript and shpaml
		# run application
		app.run()
# EOF

