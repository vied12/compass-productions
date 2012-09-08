#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : a Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 07-Sep-2012
# Last mod : 07-Sep-2012
# -----------------------------------------------------------------------------
import urllib, json

class Vimeo:

	URL = "http://vimeo.com/api/v2/video"

	@staticmethod
	def getInfo(id):
		try:
			filehandle = urllib.urlopen("%s/%s.json" % (Vimeo.URL, id))
			return json.load(filehandle)[0]
		except e:
			# FIXME: implement a log tracking system
			print e
			return None

if __name__ == "__main__":
	""" test """
	from pprint import pprint as pp
	infos = Vimeo.getInfo("6437816")
	assert json.dumps(infos)