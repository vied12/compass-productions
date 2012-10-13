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
			newsEditTmpl  : ".newsEdit.template"
			buttons       : ".actions button"
			addForm       : ".addNews form"
		}

		@cache = {
			data : null
		}

		@panelWidget   = null
		@projectWidget = null
		background     = null

	bindUI: (ui) =>
		super
		this.refresh()
		@uis.addForm.find("input[type=submit]").click (e) =>
			this.addNews(e.target)
			e.preventDefault()
			return false

	refresh: =>
		$.ajax("/api/news/admin", {dataType:'json', success:this.setData})

	setData: (data) =>
		@uis.newsContainer.find(".actual").remove()
		@cache.data = data
		for news in data
			date = new Date(news.date_creation)
			nui  = @uis.newsTmpl.cloneTemplate({
				title_en   : news.title.en
				content_en : if news.content_en then news.content.en.replace(/\n/g, "<br />") else news.content.en
				title_fr   : news.title.fr
				content_fr : if news.content_fr then news.content.fr.replace(/\n/g, "<br />") else news.content.fr
				date    : date.toDateString()
			})
			nui.attr("data-id", news._id.$oid)
			@uis.newsContainer.append(nui.fadeIn(600))
		@uis.buttons = @ui.find(@UIS.buttons)
		@uis.buttons.click (e) =>
			target    = $(e.target)
			action    = target.attr("data-action")
			list_item =  target.parents("li:first")
			id        = list_item.attr("data-id")
			switch action
				when "remove"
					this.removeNews(id, target)
				when "edit"
					news = this.getNews(id)
					nui  = @uis.newsEditTmpl.cloneTemplate({
						content_en : news.content.en
						content_fr : news.content.fr
					})
					nui.find(".title_en.out").attr("value", news.title.en)
					nui.find(".title_fr.out").attr("value", news.title.fr)
					nui.attr("data-id", news._id.$oid)
					list_item.addClass("hidden")
					nui.insertAfter(list_item)
					nui.find("input[data-action=edit]").click (e) =>
						this.editNews(id, e.target)
						e.preventDefault()
						return false
					nui.find("input[data-action=cancel]").click (e) =>
						list_item.removeClass "hidden"
						nui.remove()
						e.preventDefault()
						return false
			e.preventDefault()
			return false

	getNews: (id) =>
		for news in @cache.data
			if news._id.$oid == id
				return news
		return null

	addNews: (target) =>
		data = {
			content_en : @uis.addForm.find("textarea[name=content_en]").val()
			title_en   : @uis.addForm.find("input[name=title_en]").val()
			content_fr : @uis.addForm.find("textarea[name=content_fr]").val()
			title_fr   : @uis.addForm.find("input[name=title_fr]").val()
		}
		if data.content_en? and data.title_en?
			$(target).addClass("waiting").attr("disabled", "disabled")
			$.ajax("/api/news", {type:'POST', data:data, dataType:'json', success:(=>
				this.refresh()
				@uis.addForm.find("textarea[name=content_en]").val("")
				@uis.addForm.find("input[name=title_en]").val("")
				@uis.addForm.find("textarea[name=content_fr]").val("")
				@uis.addForm.find("input[name=title_fr]").val("")
				$(target).removeClass("waiting").removeAttr("disabled")

			)})
	editNews: (id, target) =>
		data = {
			_id     : id
			content_en : @uis.newsContainer.find("li[data-id="+id+"] textarea[name=content_en]").val()
			title_en   : @uis.newsContainer.find("li[data-id="+id+"] input[name=title_en]").val()
			content_fr : @uis.newsContainer.find("li[data-id="+id+"] textarea[name=content_fr]").val()
			title_fr   : @uis.newsContainer.find("li[data-id="+id+"] input[name=title_fr]").val()
		}
		if data.content_en? and data.title_en? and data.content_en != "" and data.title_en != "" and data.content_fr? and data.title_fr? and data.content_fr != "" and data.title_fr != ""
			$(target).addClass("waiting").attr("disabled", "disabled")
			$.ajax("/api/news", {type:'POST', data:data, dataType:'json', success: (=>
				this.refresh()
				$(target).removeClass("waiting").removeAttr("disabled")
			)})

	removeNews: (id, target) =>
		$(target).addClass("waiting").attr("disabled", "disabled")
		$.ajax("/api/news/"+id, {type:'DELETE', dataType:'json', success: (=>
			this.refresh()
			$(target).removeClass("waiting").removeAttr("waiting")
		)})

Widget.bindAll()