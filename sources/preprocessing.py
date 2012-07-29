import os, subprocess, shpaml, clevercss

def preprocess(app):
	@app.before_request
	def render():
		_render_shpaml(app)
		_render_coffee(app)
		_render_CoverCSS(app)

def _render_coffee(app):
	try:
		static_dir = app.root_path + app.static_url_path
	except AttributeError, e:    
		static_dir = app.root_path + app.static_path  # < version 0.7
	coffee_paths = []
	for path, subdirs, filenames in os.walk(app.root_path + '/lib/coffee'):
		coffee_paths.extend([
			os.path.join(path, f)
			for f in filenames if os.path.splitext(f)[1] == '.coffee'
		])
	for coffee_path in coffee_paths:
		js_path = os.path.splitext(coffee_path)[0] + '.coffee'
		if not os.path.isfile(js_path):
			js_mtime = -1
		else:
			js_mtime = os.path.getmtime(js_path)
		coffee_mtime = os.path.getmtime(coffee_path)
		if coffee_mtime >= js_mtime:
			subprocess.call(['coffee', '-o', static_dir + '/js', '-c', coffee_path], shell=False)

def _render_shpaml(app):
	templates_dir = os.path.join(app.root_path, app.template_folder)
	shpaml_dir    = 'lib/shpaml'
	shpaml_paths = []
	for path, subdirs, filenames in os.walk(os.path.join(app.root_path, shpaml_dir)):
		shpaml_paths.extend([
			os.path.join(path, f)
			for f in filenames if os.path.splitext(f)[1] == '.shpaml'
		])
	for shpaml_path in shpaml_paths:
		dest = os.path.join(templates_dir, os.path.splitext(os.path.relpath(shpaml_path, shpaml_dir))[0])
		if not os.path.isfile(dest):
			dest_mtime = -1
		else:
			dest_mtime = os.path.getmtime(dest)
		shpaml_mtime = os.path.getmtime(shpaml_path)
		if shpaml_mtime >= dest_mtime:
			with open(shpaml_path, 'r') as s:
				if not os.path.exists(os.path.dirname(dest)):
					os.makedirs(os.path.dirname(dest))
				with open(dest, 'w') as d:
					d.write(shpaml.convert_text(s.read()))

def _render_CoverCSS(app):
	dest_dir = os.path.join(app.root_path, app.static_folder, 'css')
	ccss_paths = []
	for path, subdirs, filenames in os.walk(app.root_path + '/lib/ccss'):
		ccss_paths.extend([
			os.path.join(path, f)
			for f in filenames if os.path.splitext(f)[1] == '.ccss'
		])
	for ccss_path in ccss_paths:
		dest = os.path.join(dest_dir, os.path.splitext(os.path.basename(ccss_path))[0] + '.css')
		if not os.path.isfile(dest):
			dest_mtime = -1
		else:
			dest_mtime = os.path.getmtime(dest)
		ccss_mtime = os.path.getmtime(ccss_path)
		if ccss_mtime >= dest_mtime:
			with open(ccss_path, 'r') as s:
				with open(dest, 'w') as d:
					d.write(clevercss.convert(s.read()))
# def sass(app):
# 	@app.before_request
# 	def _render_sass():
# 		static_dir = app.root_path + app.static_url_path
# 		subprocess.call(['/home/edouard/.gem/ruby/1.8/bin/sass', "--update", app.root_path + '/lib/scss:'+static_dir + '/css'], shell=False)
