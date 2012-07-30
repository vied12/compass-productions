#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : a Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 30-Jun-2012
# Last mod : 30-Jun-2012
# -----------------------------------------------------------------------------
import os, sys, subprocess, shpaml, clevercss, shutil

def preprocess(app):
	@app.before_request
	def render():
		_render_shpaml(app)
		_render_coffee(app)
		_render_coverCSS(app)

def _scan(folder, dest, action, extension, new_extension=None):
	paths = []
	for path, subdirs, filenames in os.walk(folder):
		paths.extend([
			os.path.join(path, f)
			for f in filenames if os.path.splitext(f)[1] == extension
		])
	for path in paths:
		directories   = path.split('/')
		index_lib     = directories.index('lib')
		relative_path = "/".join(directories[0:index_lib+2])
		out = os.path.join(dest, os.path.splitext(os.path.relpath(path, relative_path))[0])
		if new_extension:
			out = "%s%s" % (out, new_extension)
		if not os.path.isfile(dest):
			dest_mtime = -1
		else:
			dest_mtime = os.path.getmtime(dest)
		f_mtime = os.path.getmtime(path)
		if f_mtime >= dest_mtime:
			action(path, out) 

def _render_coffee(app):
	static_dir = app.root_path + app.static_url_path
	coffee_dir = app.root_path + '/lib/coffee'
	def action(source, dest):
		subprocess.call(['coffee', '-o', os.path.dirname(dest), '-c', source], shell=False)
	_scan(coffee_dir, static_dir + '/js', action, extension='.coffee')

def _render_shpaml(app):
	templates_dir = os.path.join(app.root_path, app.template_folder)
	shpaml_dir    = os.path.join(app.root_path, 'lib/shpaml')
	def action(source, dest):
		with open(source, 'r') as s:
			if not os.path.exists(os.path.dirname(dest)):
				os.makedirs(os.path.dirname(dest))
			with open(dest, 'w') as d:
				d.write(shpaml.convert_text(s.read()))
	_scan(shpaml_dir, templates_dir, action, extension='.shpaml')

def _render_coverCSS(app):
	dest_dir = os.path.join(app.root_path, app.static_folder, 'css')
	def action(source, dest):
		with open(source, 'r') as s:
			with open(dest, 'w') as d:
				d.write(clevercss.convert(s.read()))
	_scan(app.root_path + '/lib/ccss', dest_dir, action, extension='.ccss', new_extension='.css')

def _collect_static(app):
	static_dir = app.root_path + app.static_url_path
	lib_dir    = app.root_path + '/lib'
	dir_to_collect = ['css', 'images', 'js']
	for d in dir_to_collect:
		for path, subdirs, filenames in os.walk(os.path.join(lib_dir, d)):
			for f in [os.path.join(path, filename) for filename in filenames]:
				if os.path.isfile(f):
					dst = os.path.join(static_dir, os.path.relpath(path, 'lib/'), os.path.basename(f))
					if not os.path.exists(os.path.dirname(dst)):
						os.makedirs(os.path.dirname(dst))
					shutil.copyfile(f, dst)
# EOF
