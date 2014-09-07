#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : a Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 08-Aug-2012
# Last mod : 08-Aug-2012
# -----------------------------------------------------------------------------
# > That's what I'm learned during my intership at FFunction.
# > Don't be afraid to make something that already exits, it could 
# > be better... and easier. Less 50 lines, 2 dependances.

import urllib, json

class Flickr:

	URL          = 'https://api.flickr.com/services/rest'
	API_KEY      = "9f9b2bab6a28a524511619e703560d62"
	FORMAT_PHOTO = "http://farm%(farm)s.staticflickr.com/%(server)s/%(id)s_%(secret)s_%(quality)s.jpg"

	def __init__(self, api_key=None):
		self.apiKey = api_key or self.API_KEY

	def getSetPhotos(self, set_id, page=1, per_page=100, qualities=('q', 'z')):
		""" Return Flickr photos set as dict.
		quality can be:
			s	small square 75x75
			q	large square 150x150
			t	thumbnail, 100 on longest side
			m	small, 240 on longest side
			n	small, 320 on longest side
			-	medium, 500 on longest side
			z	medium 640, 640 on longest side
			c	medium 800, 800 on longest side†
			b	large, 1024 on longest side*
			o	original image, either a jpg, gif or png, depending on source format"""
		if type(qualities) == str: qualities = tuple(qualities)
		params = {
			'method'      : 'flickr.photosets.getPhotos',
			'format'      : 'json',
			'api_key'     : self.apiKey,
			'per_page'    : per_page,
			'page'        : page,
			'photoset_id' : set_id
		}
		filehandle = urllib.urlopen("%s/?%s" % (self.URL, urllib.urlencode(params)))
		f_res =  filehandle.read()
		# remove the function name. ie:jsonFlickrApi({...})
		f_res =  f_res[14:-1]
		f_res = json.loads(f_res)
		res = []
		for photo in f_res['photoset']['photo']:
			tmp = {}
			for quality in qualities:
				tmp[quality] = self._formatPhotos(photo, quality)
			res.append(tmp)
		return res

	def _formatPhotos(self, photo_obj, quality):
		return self.FORMAT_PHOTO % {'farm':photo_obj['farm'], 'server':photo_obj['server'], 'id':photo_obj['id'], 'secret':photo_obj['secret'], 'quality':quality}

if __name__ == "__main__":
	""" test """
	from pprint import pprint as pp
	flickr = Flickr()
	photos = flickr.getSetPhotos("72157621752440028/")
	pp(photos)
	assert json.dumps(photos)