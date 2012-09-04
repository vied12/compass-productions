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
import sources.model as model
import os, json, flask_mail

app = Flask(__name__)
app.config.from_pyfile("settings.cfg")
mail = flask_mail.Mail(app)
db   = model.Interface.GetConnection()

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

@app.route('/api/news/<id>',             methods=["GET"])
@app.route('/api/news/<id>/sort/<sort>', methods=["GET"])
@app.route('/api/news',                  methods=["POST"])
@app.route('/api/news/<id>',             methods=["DELETE"])
#FIXME: add count, skip and sort parameters
def news(id="all", sort=None):
	if request.method == "POST":
		# update
		if request.form.get("_id"):
			query = extractQuery(request.form)
			news  = db.news.News.from_json(json.dumps(query))
		else:
			news = db.news.News()
			news['content'] = request.form.get("content")
			news['title']   = request.form.get("title")
		news.save()
		return "true"
	#FIXME: not tested
	if request.method == "DELETE":
		news = model.Interface.getNews(id)
		db.news.remove({"_id":news._id})
		news.remove()
	else:
		sort = "date_creation" if sort == "date" else sort
		news = model.Interface.getNews(id, sort=sort)
		if id == "all":
			return json.dumps([_.to_json_type() for _ in news])
		else:
			return news.to_json()

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
# Utils
#
# -----------------------------------------------------------------------------
import urlparse
def extractQuery(queryDict):
	res = queryDict.copy()
	for key, value in res.items():
		if value[0] == '{' and value[-1] == '}':
			res[key] = json.loads(value)
	return res

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------

if __name__ == '__main__':
	import sys
	if len(sys.argv) > 1 and sys.argv[1] == "collectstatic":
		preprocessing._collect_static(app)
	else:
		babel = Babel(app) # i18n
		# render ccss, coffeescript and shpaml in 'templates' and 'static' dirs
		preprocessing.preprocess(app, request) 
		# run application
		app.run()
# EOF
