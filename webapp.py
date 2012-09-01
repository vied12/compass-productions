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
import os, sys, json, flask_mail

app = Flask(__name__)
app.config.from_pyfile("settings.cfg")
mail = flask_mail.Mail(app)

# -----------------------------------------------------------------------------
#
# API
#
# -----------------------------------------------------------------------------

@app.route('/api/data')
def data():
	# FIXME: set cache, set language
	with open(os.path.join(app.root_path, "data", "portfolio.json")) as f:
		return f.read()

@app.route('/api/flickr/photosSet/<set_id>/qualities/<qualities>')
def getFlickrSetPhotos(set_id, qualities):
	qualities = qualities.split(",")
	api = flickr.Flickr()
	return json.dumps(api.getSetPhotos(set_id=set_id, qualities=qualities, page=1, per_page=500))

@app.route('/api/news')
def news():
	fake = [
		{
			"date"    : 1256953732,
			"title"   : "Titre de la news 1",
			"content" : "Contenu de la news\nComment vont les affaires Johnny?"
		},
		{
			"date"    : 1256953532,
			"title"   : "Titre de la news 2",
			"content" : "Contenu de la news\nComment vont les affaires Johnny?"
		}
	]
	return json.dumps(fake)

@app.route('/api/contact', 	methods=['POST'])
def contact():
	try:
		message = request.args['message']
		msg     = flask_mail.Message(message, sender="jegrandis@gmail.com", recipients=["jegrandis@gmail.com"])
		mail.send(msg)
	except:
		return "false"
	return "true"

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
