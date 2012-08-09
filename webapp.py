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
# Last mod : 05-Aug-2012
# -----------------------------------------------------------------------------

from flask import Flask, render_template, request
from flaskext.babel import Babel
import sources.preprocessing as preprocessing
import sources.flickr as flickr
import os, sys, json

app = Flask(__name__)
app.config.from_pyfile("settings.cfg")

# -----------------------------------------------------------------------------
#
# API
#
# -----------------------------------------------------------------------------

@app.route('/api/data.json')
def data():
	# FIXME: set cache, set language
	with open(os.path.join(app.root_path, "data", "portfolio.json")) as f:
		return f.read()

@app.route('/api/flickr/photosSet/<set_id>/qualities/<qualities>/data.json')
def getFlickrSetPhotos(set_id, qualities):
	qualities = qualities.split(",")
	api = flickr.Flickr()
	return json.dumps(api.getSetPhotos(set_id=set_id, qualities=qualities, page=1, per_page=500))

# -----------------------------------------------------------------------------
#
# Site's pages
#
# -----------------------------------------------------------------------------

@app.route('/')
def index():
	return render_template('home.html')

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------

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
