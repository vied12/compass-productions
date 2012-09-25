#!/usr/bin/env python
# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : Serious Toolkit
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 03-Sep-2012
# Last mod : 23-Sep-2012
# -----------------------------------------------------------------------------
import mongokit, datetime
from mongokit import *
connection = mongokit.Connection()

class Interface:
	@staticmethod
	def GetConnection():
		return connection

	@staticmethod
	def getNews(id=None,sort=None):
		if id and id != "all":
			return Interface.GetConnection().News.one({"_id":mongokit.ObjectId(id)})
		else:
			sort = sort or "_id"
			return Interface.GetConnection().News.find().sort(sort, -1)

class MongoDBModel(mongokit.Document):
	pass

@connection.register
class News(MongoDBModel):
	__collection__ = 'news'
	__database__   = 'portfolio'
	structure = {
		'title'         : unicode,
		'content'       : unicode,
		'date_creation' : datetime.datetime,
	}
	i18n             = ['title', 'content']
	default_values   = {'date_creation' : datetime.datetime.utcnow()}
	use_dot_notation = True
	def __repr__(self):
		return '<News %r>' % (self.title)