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
# Last mod : 28-Sep-2014
# -----------------------------------------------------------------------------

from flask import Flask, render_template, request, send_file, Response, abort, session, redirect, url_for
import os, json, mimetypes, re, collections
from flask.ext.babel import Babel
from flask.ext.assets import Environment, YAMLLoader
from werkzeug.contrib.cache import SimpleCache
from flask.ext.mandrill import Mandrill
from urlparse import urlsplit, urlunsplit, parse_qs
import sources.flickr        as flickr
import sources.model         as model
import sources.vimeo         as vimeo
import datetime

app       = Flask(__name__)
app.config.from_pyfile("settings.cfg")
mail      = Mandrill(app)
interface = model.Interface(host = app.config["MONGODB_HOST"], 
							db   = app.config["MONGODB_DB"]  )
db = interface.get_database()
# assets
assets  = Environment(app)
bundles = YAMLLoader("assets.yaml").load_bundles()
assets.register(bundles)
babel   = Babel(app) # i18n
cache   = SimpleCache()

# -----------------------------------------------------------------------------
#
# API
#
# -----------------------------------------------------------------------------

@app.route('/api/data.json')
def data_json():
	ln  = get_locale()
	res = cache.get('data_json-%s' % ln)
	if res is None:
		res = json.dumps(data())
		cache.set('data_json-%s' % ln, res, timeout=60 * 60 * 24)
	return res

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
	if request.method == "POST" or request.method == "DELETE":
		if not "authenticated" in session:
			abort(401)
	if request.method == "POST":
		# update
		if request.form.get("_id"):
			query = extractQuery(request.form)
			news  = interface.get_news(request.form.get("_id"))
		else:
			news = db.News()
		news.content = request.form.get("content_en")
		news.title   = request.form.get("title_en")
		news.set_lang('fr')
		news.content = request.form.get("content_fr")
		news.title   = request.form.get("title_fr")
		news.date_creation = datetime.datetime.now()
		news.save()
		return "true"
	if request.method == "DELETE":
		news = interface.get_news(id)
		db.news.remove({"_id":news._id})
		return "true"
	else:
		admin = id == "admin"
		id    = "all" if admin else id
		sort = "date_creation" if sort == "date" else sort
		news = interface.get_news(id, sort=sort)
		res  = []
		ln   = get_locale()
		# don't translate when admin is asking
		if id == "all":
			for n in news:
				n = n.to_json()
				n = json.loads(n)
				#translate
				if not admin:
					for key in n.keys():
						if type(n[key]) is dict and n[key].keys()[0] in app.config["LANGUAGES"]:
							if ln in n[key].keys():
								n[key] = n[key][ln]
							else:
								n[key] = n[key]["en"]
				res.append(n)
			return json.dumps(res)
		else:
			return news.to_json()

@app.route('/api/contact', methods=['POST'])
def contact():
	try:
		message = request.form['message']
		sender  = request.form['email']
		mail.send_email(
			from_email = sender,
			to         = [{"email":email} for email in app.config["EMAILS"]],
			subject    = "compass Productions - Contact Page",
			text       = message,
			# https://mandrillapp.com/api/docs/messages.JSON.html#method=send
		)
	except Exception as e:
		print e
		abort(500)
	return "true"

@app.route('/api/setLanguage/<ln>', methods=['GET'])
def setLanguage(ln):
	""" Change current language in session """
	session["language"] = None
	if ln in app.config["LANGUAGES"]:
		session["language"] = ln
		return "true"
	else:
		return "false"

@babel.localeselector
@app.route('/api/getLanguage', methods=['GET'])
def get_locale():
	""" return the cached local or find the best local from request or return "en" """
	if session.get("language") and session.get("language") != "undefined":
		ln = session.get("language")
	else:
		ln = request.accept_languages.best_match(app.config["LANGUAGES"]) or "en"
		session["language"] = ln
	return ln

@app.route('/api/download', methods=["POST"])
def download():
	down_dict = cache.get('download')
	if down_dict is None:
		down_dict = {}
		with open(os.path.join(app.root_path, "data", 'portfolio.json')) as f:
			data = json.load(f, object_pairs_hook=collections.OrderedDict)
			for work_index, work in enumerate(data.get("works", tuple())):
					press = work.get("press")
					if press and press.get("presskit"):
						presskit = press.get("presskit")
						down_dict[presskit.get("password")] = presskit.get("link")
		cache.set('download', down_dict)
	res = down_dict.get(request.form["password"])
	if not res:
		abort(401)
	return res
# -----------------------------------------------------------------------------
#
# Site's pages
#
# -----------------------------------------------------------------------------

def get_project_by_name(name):
	for project in data()["works"]:
		if project["key"] == name:
			return project
	return None

@app.route('/')
def index():
	_escaped_fragment_ = request.args.get("_escaped_fragment_")
	project = None
	if _escaped_fragment_:
		params = parse_qs(_escaped_fragment_)
		_project = params.get("project")
		_ln = params.get("ln")
		if _ln:
			setLanguage(_ln[0])
		if _project:
			project = get_project_by_name(_project[0])
	return render_template('home.html', project=project)

@app.route('/admin', methods=['GET'])
def admin():
	if "authenticated" in session:
		return render_template('admin.html')
	else:
		return redirect(url_for('authenticate'))

@app.route('/authenticate', methods=['GET', 'POST'])
def authenticate():
	if request.method == 'POST' and request.form["password"] == app.config["ADMIN_PASSWORD"]:
		session['authenticated'] = True
		return redirect(url_for('admin'))
	return render_template('auth.html')

@app.route('/logout')
def logout():
	session.pop('authenticated', None)
	return redirect(url_for('admin'))

@app.route('/static/videos/<video>', methods=['GET'])
def video(video):
	"""serv videos as partial content"""
	path = os.path.join(app.static_folder, "videos", video)
	return send_file_partial(path)

# -----------------------------------------------------------------------------
#
# Utils
#
# -----------------------------------------------------------------------------
def data():
	ln  = get_locale()
	res = cache.get('data-%s' % ln)
	if res is None:
		with open(os.path.join(app.root_path, "data", 'portfolio.json')) as f:
			data = json.load(f, object_pairs_hook=collections.OrderedDict)
			# translate
			for work_index, work in enumerate(data.get("works", tuple())):
				for key in work.keys():
					# if value is a pair of {en: ..., fr: ...}
					if type(work[key]) == collections.OrderedDict:
						if work[key].keys()[0] in app.config["LANGUAGES"]:
							if ln in work[key].keys():
								data["works"][work_index][key] = work[key][ln]
							else:
								data["works"][work_index][key] = work[key][app.config["LANGUAGES"][0]]
			# add some infos for videos
			# for work_index, work in enumerate(data.get("works", tuple())):
			# 	videos = work.get("videos", tuple())
			# 	if videos:
			# 		data["works"][work_index]["videos"] = []
			# 	for video in videos:
			# 		info = vimeo.Vimeo.getInfo(video)
			# 		if info:
			# 			data["works"][work_index]["videos"].append(info)
			# remove passwords from presskit
			for work_index, work in enumerate(data.get("works", tuple())):
				press = work.get("press")
				if press and press.get("presskit"):
					data["works"][work_index]["press"]["presskit"] = True
			res = data
			cache.set('data-%s' % ln, data, timeout=60 * 60 * 24)
	return res

def extractQuery(queryDict):
	res = queryDict.copy()
	for key, value in res.items():
		if value[0] == '{' and value[-1] == '}':
			res[key] = json.loads(value)
	return res

@app.after_request
def after_request(response):
	response.headers.add('Accept-Ranges', 'bytes')
	return response

def send_file_partial(path):
	""" 
		Simple wrapper around send_file which handles HTTP 206 Partial Content
		(byte ranges)
		TODO: handle all send_file args, mirror send_file's error handling
		(if it has any)
	"""
	range_header = request.headers.get('Range', None)
	if not range_header: return send_file(path)
	size = os.path.getsize(path)    
	byte1, byte2 = 0, None
	m = re.search('(\d+)-(\d*)', range_header)
	g = m.groups()
	if g[0]: byte1 = int(g[0])
	if g[1]: byte2 = int(g[1])
	length = size - byte1
	if byte2 is not None:
		length = byte2 - byte1
	data = None
	with open(path, 'rb') as f:
		f.seek(byte1)
		data = f.read(length)
	rv = Response(data, 
		206,
		mimetype=mimetypes.guess_type(path)[0], 
		direct_passthrough=True)
	rv.headers.add('Content-Range', 'bytes {0}-{1}/{2}'.format(byte1, byte1 + length - 1, size))
	return rv

@app.template_filter('relative_url')
def relative_url_filter(s):
	if s.startswith(app.static_url_path):
		return s[1:]
	return s

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------

if __name__ == '__main__':
	app.run(extra_files=("assets.yaml",), host="0.0.0.0")

# EOF
