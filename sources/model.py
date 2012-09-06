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
# Last mod : 03-Sep-2012
# -----------------------------------------------------------------------------
import mongokit, datetime

connection = mongokit.Connection()

class Interface:
	@staticmethod
	def GetConnection():
		return connection['portfolio']

	@staticmethod
	def getNews(id=None,sort=None):
		if id and id != "all":
			return Interface.GetConnection().news.News.one({"_id":mongokit.ObjectId(id)})
		else:
			if sort:
				return Interface.GetConnection().news.News.find().sort(sort, 1)
			else:
				return Interface.GetConnection().news.News.find()

class MongoDBModel(mongokit.Document):
	pass

@connection.register
class News(MongoDBModel):
	__collection__ = 'portfolio_news'
	__database__   = 'portfolio'
	structure = {
		'title'         : unicode,
		'content'       : unicode,
		'date_creation' : datetime.datetime,
	}
	# validators = {
	# 	'name': max_length(50),
	# 	'email': max_length(120)
	# }
	default_values = {
		'date_creation' : datetime.datetime.utcnow()
	}
	use_dot_notation = True
	def __repr__(self):
		return '<News %r>' % (self.title)