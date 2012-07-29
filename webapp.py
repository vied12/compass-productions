#!/usr/bin/python
from flask import Flask, render_template
from sources.preprocessing import preprocess
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
	app.config.from_pyfile("settings.cfg")
	preprocess(app) # render ccss, coffeescript and shpaml
	# run application
	app.run()




