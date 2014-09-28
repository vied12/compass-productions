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
# Last mod : 28-Sep-2014
# -----------------------------------------------------------------------------
import mongokit, datetime

# connection = mongokit.Connection()

class Interface:

	def __init__(self, db, host):
		self.db         = db
		self.host       = host
		self.connection = mongokit.Connection(self.host)
		self.connection.register([Interface.News])

	# @staticmethod
	def get_connection(self):
		return self.connection

	def get_database(self, database=None):
		database = database or self.db
		return self.get_connection()[database]

	# @staticmethod
	def get_news(self, id=None,sort=None):
		if id and id != "all":
			return self.get_database().News.one({"_id":mongokit.ObjectId(id)})
		else:
			sort = sort or "_id"
			return self.get_database().News.find().sort(sort, -1)

	class MongoDBModel(mongokit.Document):
		pass

	class News(MongoDBModel):
		__collection__ = 'news'
		structure = {
			'title'         : unicode,
			'content'       : unicode,
			'date_creation' : datetime.datetime,
		}
		i18n             = ['title', 'content']
		default_values   = {'date_creation' : datetime.datetime.utcnow()}
		use_dot_notation = True


# EOF
