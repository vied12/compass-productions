#!/usr/bin/python
from flask import Flask, render_template
import sys, sources.preprocessing
app = Flask(__name__)

@app.route('/')
def index():
	return render_template('home.html')

# @app.context_processor
# def context():
# 	return {
# 		'STATIC_URL'
# 	}

if __name__ == '__main__':
	if len(sys.argv) > 1 and sys.argv[1] == "collectstatic":
		sources.preprocessing._collect_static(app)
	else:
		app.config.from_pyfile("settings.cfg")
		sources.preprocessing.preprocess(app) # render ccss, coffeescript and shpaml
		# run application
		app.run()




