# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 14-Sep-2012
# Last mod : 14-Sep-2012
# -----------------------------------------------------------------------------
window.portfolio_admin = {}

Widget   = window.serious.Widget
URL      = new window.serious.URL()
Format   = window.serious.format
# -----------------------------------------------------------------------------
#
# NEWS
#
# -----------------------------------------------------------------------------

class portfolio_admin.News extends Widget

	constructor: ->
		@UIS = {
			newsContainer : "ul"
			newsTmpl      : ".news.template"
			buttons       : ".actions button"
		}

		@cache = {
			data : null
		}

		@panelWidget   = null
		@projectWidget = null
		background     = null

	bindUI: (ui) =>
		super
		$.ajax("/api/news/all", {dataType: 'json', success : this.setData})

	setData: (data) =>
		@cache.data = data
		for news in data
			date = new Date(news.date_creation)
			nui  = @uis.newsTmpl.cloneTemplate({
				title   : news.title
				content : news.content
				date    : date.toDateString()
			})
			nui.attr("data-id", news._id.$oid)
			@uis.newsContainer.append(nui)
		@uis.buttons = @ui.find(@UIS.buttons)
		@uis.buttons.click (e) =>
			target = $(e.target)
			action = target.attr("data-action")
			id     = target.parents("li:first").attr("data-id")
			switch action
				when "remove"
					this.removeNews(id)

	removeNews: (id) =>
		$.ajax("/api/news/"+id, {type: 'DELETE', dataType: 'json', success : this.setData})

Widget.bindAll()