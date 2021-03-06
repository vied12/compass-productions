# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 23-Sep-2012
# -----------------------------------------------------------------------------
window.portfolio = {}

Widget   = window.serious.Widget
URL      = new window.serious.URL()
Format   = window.serious.format
Utils    = window.serious.Utils

# -----------------------------------------------------------------------------
#
# Navigation
#
# -----------------------------------------------------------------------------
class portfolio.Navigation extends Widget

	constructor: ->
		@UIS = {
			tilesList        : ".Main .tile, .Works .tile, .InDevelopment .tile"
			brandTile        : ".brand.tile"
			main             : ".Main"
			works            : ".Works"
			pageMenu         : ".PageMenu"
			menus            : ".menu"
			worksTiles       : ".Works .tile"
			mainTiles        : ".Main .tile"
			pageLinks        : ".Page.links"
			menuRoot         : ".Page.links .menuRoot"
		}

		@CONFIG = {
			tileMargin : 4
			pages      : ["project", "contact", "news", "page", "single-page"]
		}

		@cache = {
			currentPage    : null
			data           : null
		}
		@panelWidget   = null
		@projectWidget = null
		background     = null

	bindUI: (ui) =>
		super
		@panelWidget      = Widget.ensureWidget(".FooterPanel")
		@projectWidget    = Widget.ensureWidget(".Project")
		@backgroundWidget = Widget.ensureWidget(".Background")
		@singlePageWidget = Widget.ensureWidget(".SinglePage")
		# download data
		$.ajax("/api/data.json", {dataType: 'json', success : @setData})
		# binds events
		@uis.tilesList.click((e) => @tileSelected(e.currentTarget or e.srcElement))
		@uis.brandTile.click((e) => @tileSelected(e.currentTarget or e.srcElement))
		@uis.menuRoot .click((e) => e.preventDefault(); @togglePanelMenu())
		$('body').bind('backToHome'           , (e)        => @showMenu("main"))
		$('body').bind('updateOpenPanelButton', (e,opened) => @updateOpenPanelButton(opened))
		$('body').bind('hidePanelToggler'     , (e,opened) => @uis.menuRoot.addClass "hidden")
		$('body').bind('showPanelToggler'     , (e,opened) => @uis.menuRoot.removeClass "hidden")
		return this

	onUrlChange: =>
		# hide single page widget if needed
		@cache.currentPage = null
		@singlePageWidget.hide() unless URL.get("page") == "single-page"
		if URL.hasChanged("menu")
			menu = URL.get("menu")
			if menu
				this.showMenu(menu)
		if URL.hasChanged("page")
			@cache.currentPage = null
			page = URL.get("page")
			if page
				this.showPage(page)
				$('body').trigger("pageChanged", page)

	setData: (data) =>
		@cache.data = data
		@projectWidget.setData(data)
		# update view
		@setTitles()
		# init from url
		params = URL.get()
		if params.page?
			this.showPage(params.page)
		else if params.menu?
			this.showMenu(params.menu)
		else
			this.showMenu("main")
		# bind url change
		URL.onStateChanged(@onUrlChange)

	setTitles: =>
		that = this
		@uis.tilesList.filter("[data-title]").each ->
			element = $(this)
			element.find(".wrapper").html(that.getProjectByName(element.data("title")).title)

	getProjectByName: (name) =>
		for project in @cache.data.works
			if project.key == name
				return project

	showMenu: (menu) =>
		###
		show the given menu, hide the previous opened menu

		###
		# default background for menus
		@backgroundWidget.image("index_bg.jpg", true) unless menu is "page"
		if menu == "main"
			@backgroundWidget.darkness(0)
			@backgroundWidget.resetClass()
			@backgroundWidget.removeVideo()
			# $('body').trigger "cancelDelayedPanel"
		# hide panel if menu is not a page (i.e: work and main)
		$("body").trigger("hidePanel") if menu not in ["page"]
		@updateGoBackLink(menu)
		@updateOpenPanelButton()
		# show tiles of selected menu
		menu_ui = @ui.find "[data-menu="+menu+"]"
		if not menu_ui.length > 0
			console.error("WHY?", menu_ui)
			return false
		@uis.menus.addClass "hidden"
		tiles = menu_ui.find(".tile")
		tiles.addClass("no-animation").removeClass("show")
		menu_ui.removeClass "hidden"
		# Animation, one by one, fadding effect
		i     = 0
		interval = setInterval(=>
			$(tiles[i]).removeClass("no-animation").addClass("show")
			i += 1
			if i == tiles.length
				clearInterval(interval)
		, 100) # time between each iteration

	updateGoBackLink: (menu_to_go) =>
		###
		Show the go back home link
		###
		@uis.pageLinks.toggleClass("hidden", menu_to_go is "main")

	togglePanelMenu: =>
		if not @panelWidget.isOpened()
				setTimeout( (=> @panelWidget.open()), 100)
			else
				setTimeout( (=> @panelWidget.hide()), 100)

	updateOpenPanelButton: (is_open=true) =>
		if @cache.currentPage? and not is_open
			@uis.menuRoot.removeClass "hidden"
		else
			@uis.menuRoot.addClass "hidden"

	showPage: (page) =>
		### set page menu (single tile) ###
		target_to_find = URL.get("project") or page
		page_tile = @ui.find(".nav[data-target="+(URL.get("project") or page)+"]:first")
		# if no result, retry with the new notation "single-page:<project_name>"
		if URL.get("project") and page_tile.length < 1
			page_tile = @ui.find(".nav[data-target='#{page}:#{URL.get("project")}']:first")
		@uis.pageMenu.html(page_tile.clone())
		@cache.currentPage = page
		this.showMenu("page")
		if page == "single-page"
			params = URL.get()
			@singlePageWidget.setProject(@getProjectByName(params.project))
			@singlePageWidget.show()
		else
			if URL.get("cat")?
				$("body").trigger("setDirectPanelPage", page)
			else
				$("body").trigger("setPanelPage", page)

	tileSelected: (tile_selected_ui) =>
		###
		update the url, depending the selected tile

		###
		tile_selected_ui = $(tile_selected_ui)
		if tile_selected_ui.hasClass "tile"
			target = tile_selected_ui.attr "data-target"
			# check if there is a menu for the current target
			if @ui.find("[data-menu='"+target+"']").length > 0
				# FIXME: should not be here, cat and project are not on this widget
				URL.update({menu:target, page:null, project:null, cat:null})
			else # the target is a page
				target_root = target.split(":")[0]
				if target_root in @CONFIG.pages
					project = target.split(":")[1] or null
					URL.update({page:target_root, menu:null, project:project, cat:null})
				else
					# project selected
					URL.update({page:"project", project:target, menu:null, cat:null})

# -----------------------------------------------------------------------------
#
# Background
#
# -----------------------------------------------------------------------------
class portfolio.Background extends Widget

	constructor: ->
		@UIS = {
			image     : ".image.template"
			video     : ".video"
			mask      : ".mask"
			darkness  : ".darkness"
			mousemask : ".mousemask"
		}

		@CONFIG = {
			imageUrl : "/static/images/"
			videoUrl : "/static/videos/"
		}

		@CACHE = {
			image       : null
			suspended   : false
		}

	bindUI: (ui) ->
		super
		$(window).resize(=>(this.relayout()))
		$('body').bind("darkness", (e, darkness) => this.darkness(darkness))

	relayout: =>
		resize = (that, flexibleSize) ->
			if flexibleSize == "full"
			 	flexibleSize = "100%"
			aspectRatio = that.height() / that.width()
			#ratio compliant
			windowRatio = $(window).height() / $(window).width()
			if windowRatio > aspectRatio
				that.height($(window).height())
				that.width(flexibleSize)
			else
				that.height(flexibleSize)
				that.width($(window).width())
		resize(@uis.image, "full")
		resize(@uis.mask, "full")

	setProject: (project_obj) =>
		this.resetClass()
		setTimeout((=> @ui.addClass project_obj.key), 0.20)
		if project_obj.backgroundVideos
			if Modernizr.video
				@video(project_obj.backgroundVideos)
			else
				@image(project_obj.backgroundImage)
		else if project_obj.backgroundImage
			@image(project_obj.backgroundImage)
		else
			@removeVideo()

	suspend: =>
		@CACHE.suspended = true
		@uis.image.addClass "pasla"
		@ui.find('video.actual').addClass "hidden"

	restore: =>
		@ui.find('video.actual').removeClass "hidden"
		@uis.image.removeClass "pasla"
		@CACHE.suspended = false

	removeVideo: =>
		@ui.find('video.actual').remove()

	video: (data) =>
		#swap on image if playing video is not supported for format,
		#use image's tag give better control on relayoupropting than poster attribute of <video>
		old_nui  = @ui.find('video.actual')
		nui      = @uis.video.cloneTemplate().addClass "hidden"
		@uis.image.addClass "pasla"
		nui.prop('muted', true)
		for file in data
			extension = file.split('.').pop()
			source=$('<source />').attr("src", @CONFIG.videoUrl+file)
			type = extension
			if extension == "ogv" then type = "ogg"
			source.attr("type", "video/#{type}")
			nui.append(source)
		if @CACHE.image != null
		 	nui.attr("poster", @CONFIG.imageUrl+@CACHE.image)
		#wait until video is playable before swap with old video
		nui.on("canplay canplaythrough", =>
			if not @CACHE.suspended
				old_nui.remove()
				nui.removeClass "hidden"
		)
		@uis.video.after(nui)

	image: (filename, is_default=false) =>
		old_nui = @ui.find('.image.actual')
		old_nui.addClass "pasla"
		if is_default
			$("<img/>").attr('src', "#{@CONFIG.imageUrl}#{filename}").load =>
				@uis.image.css("background-image", "url(#{@CONFIG.imageUrl}#{filename})")
				@uis.image.removeClass "pasla"
				setTimeout((=> old_nui.remove()), 1000)
			return
		@uis.image.addClass "pasla"
		nui = @uis.image.cloneTemplate().addClass("pasla").css("background-image", "")
		@uis.video.before(nui)
		this.relayout(@uis.image)
		@CACHE.image=filename
		$("<img/>").attr('src', "#{@CONFIG.imageUrl}#{filename}").load(=>
			nui.css("background-image", "url(#{@CONFIG.imageUrl}#{filename})")
			nui.removeClass "pasla"
			setTimeout((=> old_nui.remove()), 1000)
		)

	darkness : (darklevel)=>
		@uis.darkness.css("opacity", darklevel)

	resetClass: =>
		@ui.removeClass()
		@ui.addClass "Background widget"


# -----------------------------------------------------------------------------
#
# Single Page / without panel
#
# -----------------------------------------------------------------------------
class portfolio.SinglePage extends Widget

	constructor: ->
		@UIS =
			title   : ".SinglePage__title"
			cover   : ".SinglePage__cover"
			body    : ".SinglePage__body"
			wrapper : ".SinglePage__wrapper"

	bindUI:(ui) =>
		super
		$("body").bind("relayoutContent", this.relayout)
		return this


	setProject: (project) =>
		@ui.attr("class", "SinglePage widget #{project.key}")
		@uis.title.html(project.title)
		# NOTE: thumbnail disabled
		# @uis.cover.html($("<img />").attr("src", "static/images/#{project.cover}"))
		if project.synopsis.body?
			@uis.body.html(project.synopsis.body)
		else if project.synopsis.url?
			@uis.body.load "static/#{project.synopsis.url}?timestamp=#{new Date().getTime()}", @relayout

	relayout: =>
		setTimeout(=>
			height = $(window).height() - (@ui.offset().top + 40*2)
			@uis.wrapper.css({height: height})
				.jScrollPane({hideFocus:true})
		, 100)

# -----------------------------------------------------------------------------
#
# Panel
#
# -----------------------------------------------------------------------------

class portfolio.Panel extends Widget

	constructor: ->

		@OPTIONS = {
			panelHeightClosed : 40
			delay : 0
		}
		@PAGES = ["project", "contact", "news"]
		@UIS = {
			wrapper     : ".wrapper:first"
			pages 		: ".pages"
			close       : ".close"
			contents 	: ".content"
		}

		@cache = {
			isOpened    : false
			currentTab  : null
			currentPage : null
			footerBarHeight : 0
			tilesHeight : null
		}

	bindUI: (ui) =>
		super
		@backgroundWidget = Widget.ensureWidget(".Background")
		@cancelDelay=false
		#bind events
		$('body').bind 'setPanelPage'      , (e, page) => this.goto page
		$('body').bind 'setDirectPanelPage', (e, page) => this.goto(page, false)
		$('body').bind 'hidePanel'         , this.hide
		$('body').bind 'cancelDelayedPanel', this.cancelDelayedPanel
		$(window).resize(=>(this.relayout(@cache.isOpened)))
		@uis.close.click (e)=>
			e.preventDefault()
			Widget.ensureWidget(".Navigation").togglePanelMenu()
			this.hide()
		@relayout()
		return this

	goto: (page, delay=true) =>
		#close all pages
		@uis.wrapper.find('.page').removeClass "show"
		#show the one
		@uis.wrapper.find('.'+Format.StringFormat.Capitalize(page)).addClass "show"
		@uis.wrapper.find('.'+Format.StringFormat.Capitalize(page)+' .content').addClass "active"
		#open this panel
		if delay then this.open(page) else this.open()
		#cache
		@cache.currentPage = page

	relayout: (open) =>
		@cache.isOpened = open
		if @cache.isOpened
			window_height = $(window).height()
			height = $(window).height() - 218
			if height > 0
				@ui.css({height : height})
			# just under the navigation
			@ui.css({bottom : $(".FooterBar").height()})
		else
			@ui.css({bottom : 0 - @ui.height()})
		# FIXME: ugly, to center the footer bar links
		offset_left = parseInt($(".FooterBar .wrapper:first").offset().left) + 60
		$(".Page.links").css({left:offset_left})
		setTimeout((=>$('body').trigger("relayoutContent")), 100)

	hide: =>
		@cache.isOpened = false
		this.relayout(false)
		setTimeout((=> @uis.wrapper.addClass "hidden"), 100)
		@backgroundWidget.darkness(0)
		$('body').trigger "updateOpenPanelButton", false

	open: (page) =>
		if page == "project" then delay = @OPTIONS.delay else delay = 0
		setTimeout(=>
			if not @cancelDelay
				@cache.isOpened = true
				@ui.removeClass "hidden"
				@uis.wrapper.removeClass "hidden"
				this.relayout(true)
				@backgroundWidget.darkness(0.6)
				$('body').trigger "updateOpenPanelButton", true
				@cancelDelay=false
		,delay)

	cancelDelayedPanel: =>
		@cancelDelay=true

	isOpened: =>
		@cache.isOpened

# -----------------------------------------------------------------------------
#
# Flickr Gallery
#
# -----------------------------------------------------------------------------

class portfolio.FlickrGallery extends Widget

	constructor: ->

		@UIS = {
			list      : ".photos"
			photoTmpl : "li.photo.template"
		}

		@cache = {
			data : null
		}

		@imagePlayer = null

	bindUI: (ui) =>
		super
		@imagePlayer = Widget.ensureWidget(".ImagePlayer")
		return this

	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z", {dataType: 'json', success : this.setData})
	getPhotoSet: => return @cache.data

	_makePhotoTile: (photoData, index) =>
		nui = @uis.photoTmpl.cloneTemplate()
		nui.find(".image").css("background-image", "url("+photoData.q+")")
		nui.find("a").attr("href", "#+item="+index)
		@uis.list.append(nui)

	setData: (data) =>
		#clean old gallery
		@uis.list.find('li:not(.template)').remove()
		#update	cache data
		@cache.data = data
		#make the first tiles
		for photo, index in data
			this._makePhotoTile(photo, index)
		# show media player if item params exists in URL hash
		URL.enableLinks(@uis.list)
		params = URL.get()
		if params.item and URL.get("cat") == "gallery"
			@imagePlayer.setData(this.getPhotoSet())
		URL.onStateChanged =>
			if URL.get("item")
				if URL.get("cat")? and URL.get("cat") == "gallery"
					@imagePlayer.setData(this.getPhotoSet())

# -----------------------------------------------------------------------------
#
# News
#
# -----------------------------------------------------------------------------

class portfolio.News extends Widget

	constructor: ->

		@UIS = {
			newsTmpl      : ".template"
			newsContainer : "ul"
			content       : ".content"
		}

		@cache = {
			data : null
		}

	bindUI: (ui) =>
		super
		$.ajax("/api/news/all", {dataType: 'json', success : this.setData})
		$("body").bind("relayoutContent", this.relayout)
		return this

	relayout: =>
		top_offset = $('.FooterPanel').height() - 80
		@ui.find(".content").css({height: top_offset}).jScrollPane({hideFocus:true})

	setData: (data) =>
		@cache.data = data
		for news in data
			date = new Date(news.date_creation)
			nui = @uis.newsTmpl.cloneTemplate({
				body:news.content.replace(/\n/g, "<br />")
				date:date.toDateString()
			})
			nui.find(".title").append(news.title)
			@uis.newsContainer.append(nui)

# -----------------------------------------------------------------------------
#
# Contact
#
# -----------------------------------------------------------------------------

class portfolio.Contact extends Widget

	constructor: ->

		@UIS = {
			main        : ".main"
			form        : ".contactForm"
			email       : ".email"
			message     : ".message"
			results     : ".result"
			errorMsg    : ".result.error"
			successMsg  : ".result.success"
			content     : ".content"
		}

		@CONFIG = {
			minMessageHeight : 200
		}

		@ACTIONS = ["showForm", "showMain", "sendMessage"]

	bindUI: (ui) =>
		super
		# reset when arriving
		$('body').bind('pageChanged', (e,page) => this.showMain() if page == "contact")
		$('body').bind('relayoutContent', this.relayout)
		return this

	relayout: =>
		top_offset = $(".FooterPanel").height() - 80
		messageHeight = $(window).height() - @uis.message.offset().top - 190
		if messageHeight < @CONFIG.minMessageHeight
			messageHeight = @CONFIG.minMessageHeight
		@uis.message.css({height:messageHeight})
		@uis.content.css({height: top_offset}).jScrollPane({hideFocus:true})

	showMain: =>
		@uis.form.addClass "hidden"
		@uis.main.removeClass "hidden"
		this.relayout()

	showForm: =>
		@uis.form.removeClass "hidden"
		@uis.main.addClass "hidden"
		@uis.results.addClass "hidden"
		this.relayout()

	sendMessage: =>
		@uis.results.addClass "hidden"
		email   = @uis.form.find('[name=email]').val()
		message = @uis.form.find('[name=message]').val()
		$.ajax("/api/contact",
			{
				type: "POST"
				dataType: 'json'
				data: {email:email, message:message}
				success : ((msg)=>
					@uis.successMsg.removeClass "hidden"
				)
				error : ((msg)=>
					@uis.errorMsg.removeClass "hidden"
				)
			}
		)

# -----------------------------------------------------------------------------
#
# PROJECT
#
# -----------------------------------------------------------------------------

class portfolio.Project extends Widget

	constructor: ->

		@UIS = {
			tabs        : ".tabs"
			tabContent  : ".content"
			tabContents : ".contents"
			tabList     : ".tabs li"
		}
		@cache = {
			footerBarHeight : 0
			data            : null
			externalVideo   : false
		}
		@CATEGORIES    = ["synopsis", "videos", "gallery", "screenings", "credits", "press", "links", "distribution", "facebook"]
		@flickrGallery = null
		@videoPlayer   = null
		@downloader    = null

	bindUI: (ui) =>
		super
		@navigationWidget = Widget.ensureWidget(".Navigation")
		@flickrGallery    = Widget.ensureWidget(".content.gallery")
		@videoPlayer      = Widget.ensureWidget(".VideoPlayer")
		@backgroundWidget = Widget.ensureWidget(".Background")
		# enable dynamic links (#+cat=...)
		URL.enableLinks(@ui)
		$("body").bind("relayoutContent", this.relayout)
		@downloader    = Widget.ensureWidget(".Download")
		@ui.find(".presskit a").click((=> @downloader.show()))

	relayout: =>
		top_offset = $('.FooterPanel').height() - 100
		@ui.find(".content").css({height: top_offset}).jScrollPane({hideFocus:true})

	setData: (data) =>
		@cache.data = data
		# init from url
		params = URL.get()
		if params.project
			this.setProject(params.project)
			this.selectTab(URL.get("cat") or "synopsis")
		# init videoPlayer if needed
		if params.item
			if (URL.get("cat")? and URL.get("cat") == "videos")
				@videoPlayer.setData(this.getProjectByName(URL.get("project")).videos)
			# see flickr widget for images's MediaPlayer
		# bind url change
		URL.onStateChanged =>
			if URL.hasChanged("project")
				if URL.get("project")?
					this.setProject(URL.get("project"))
					this.selectTab(URL.get("cat") or "synopsis")
			if URL.hasChanged("cat")
				if URL.get("cat")?
					this.selectTab(URL.get("cat"))
			if URL.get("item")?
				if (URL.get("cat")? and URL.get("cat") == "videos")
					@videoPlayer.setData(this.getProjectByName(URL.get("project")).videos)

	getProjectByName: (name) =>
		@navigationWidget.getProjectByName(name)

	setProject: (project) =>
		project_obj = this.getProjectByName(project)
		this.setMenu(project_obj)
		this.setContent(project_obj)
		@backgroundWidget.setProject(project_obj)

	setMenu: (project) =>
		@uis.tabList.addClass "hidden"
		for category in @CATEGORIES
			if project[category]?
				# special case for Nana G. and Me
				if project.key == "nana" and category == "videos"
					@uis.tabs.find("."+category+"Nana").removeClass("hidden")
				else
					@uis.tabs.find("."+category).removeClass("hidden")
		# special case for Bagdad film, the video is on an external web site
		if project.facebook?
			@ui.find("[data-name=facebook]").attr('href', project.facebook)
		if project.videos?
			if project.videos.length == 0
				@cache.externalVideo = true
				@ui.find("[data-name=videos]").bind("click.external", (e) =>
						e.preventDefault()
						window.open('http://www.nfb.ca/film/baghdad_twist','_blank')
					)
			else
				@cache.externalVideo = false
				@ui.find("[data-name=videos]").unbind("click.external")
		# update dynamic links
		URL.enableLinks(@uis.tabs)

	setContent: (project) =>
		for category, value of project
			if category in @CATEGORIES
				nui = @uis.tabContents.find("[data-name="+category+"] .wrapper")
				switch category
					when "synopsis"
						nui.find(".actual").remove()
						synopsis_nui = nui.find('.template').cloneTemplate(value)
						nui.append(synopsis_nui)
						readmoreLink = nui.find('.readmore')
						body_nui     = nui.find('.actual .body')
						body_nui.html(body_nui.html().replace(/\n/g, "<br />"))
						# if teaser is in json, teaser is displayed with readmore link,
						teaser = nui.find(".actual .teaser")
						if value.teaser?
							teaser.removeClass "hidden"
							body_nui.css({
								display:'none',
							})
							teaser.html(teaser.html().replace(/\n/g, "<br />"))
							readmoreLink.removeClass "hidden"
							body_nui.removeClass "readmoreFx"
							$('body').bind('readmore.init', =>
								body_nui.css("display":"none")
								readmoreLink.removeClass "hidden"
							)
							readmoreLink.click((e) =>
								e.preventDefault()
								body_nui.removeClass "hidden"
								body_nui.css({display:'block'})
								readmoreLink.addClass "hidden"
								setTimeout((=>
									body_nui.addClass "readmoreFx"
									this.relayout()
									), 200)
							)
						# else body is displayed alone
						else
							teaser.addClass 'hidden'
							readmoreLink.addClass "hidden"

							body_nui.css({
								display:'block',
								opacity:1
							})
					when "videos"
						list = nui.find("ul")
						# resets
						list.find("li:not(.template)").remove()
						for video, i in value
							video_nui = nui.find(".template").cloneTemplate({
								duration : Format.NumberFormat.SecondToString(video.duration)
								title    : video.title
							})
							video_nui.find('img').attr("src", video.thumbnail_large)
							video_nui.find('a').attr("href", "#+item="+i)
							list.append(video_nui)
						# update dynamic links
						URL.enableLinks(list)
					when "gallery"
						@flickrGallery.setPhotoSet(project.gallery)
					when "press"
						nui.find(".actual").remove()
						if value.press?
							for press in value.press
								press_nui = nui.find('.template').cloneTemplate(press)
								nui.append(press_nui)
						presskit = nui.find(".presskit")
						if value.presskit?
							presskit.removeClass("hidden")
							presskit.find("a").attr("href", value.presskit.link)
						else
							presskit.addClass("hidden")
					when "credits"
						nui.find(".actual").remove()
						for credit in value
							credit_nui = nui.find('.template').cloneTemplate(credit,true)
							nui.append(credit_nui)
					when "screenings"
						nui.find(".actual").remove()
						for screening in value
							screening_nui = nui.find('.template').cloneTemplate(screening, true)
							nui.append(screening_nui)
					when "links"
						nui.find(".actual").remove()
						for link in value
							link_nui = nui.find(".template").cloneTemplate(link)
							link_nui.find('a').html(link.description).attr("href", link.link)
							nui.append(link_nui)
					when "distribution"
						nui.empty()
						nui.append(value.replace(/\n/g, "<br />"))

	selectTab: (category) =>
		if not (@cache.externalVideo and category=="videos")
			@uis.tabContent.removeClass "active"
			@uis.tabContent.removeClass "show"
			@uis.tabContent.addClass "hidden"
			@uis.tabList.find("a").removeClass "active"
			@uis.tabList.find("[data-name="+category+"]").addClass "active"
			tab_nui = @uis.tabContents.find("[data-name="+category+"]")
			tab_nui.removeClass "hidden"
			setTimeout((=>tab_nui.addClass "active"), 100)
			$('body').trigger "readmore.init"
			this.relayout()

# -----------------------------------------------------------------------------
#
# MEDIA PLAYER
#
# -----------------------------------------------------------------------------

class portfolio.MediaPlayer extends Widget

	constructor: ->

		@OPTIONS = {
			nbTiles : 5
		}

		@cache = {
			data            : null
			currentPage     : null
			isShown         : false
			currentItem     : null
			isTrailer       : null
		}

		@ACTIONS = ["hide", "next", "previous"]

	bindUI: (ui) =>
		super
		@backgroundWidget = Widget.ensureWidget(".Background")
		URL.onStateChanged(this.onURLStateChanged)
		$(window).resize(this.relayout)

	relayout: =>
		if @cache.data? and @cache.isShown
			ratio = @cache.data[@cache.currentItem].ratio
			if (not ratio?)
				img = $("<img>").attr("src", @cache.data[@cache.currentItem].media)
				img.load (e) =>
					ratio = @cache.data[@cache.currentItem].ratio = e.currentTarget.width/e.currentTarget.height
					return this.relayout()
			else
				player_width_max  = $(window).width() - 100
				player_height     = @uis.panel.offset().top - 50
				player_width      = player_height * ratio
				if player_width > player_width_max
					player_width  = player_width_max
					player_height = player_width / ratio
				@uis.player.attr({height:player_height, width:player_width})
				@uis.playerContainer.css("width", player_width) # permit margin auto on player
			# center waiter
			@uis.waiter.css {top: $(window).height()/2}

	onURLStateChanged: =>
		if (@cache.isShown)
			if URL.hasChanged("item")
					if URL.get("item")
						this.setMedia(URL.get("item"))
					else
						this.hide()

	setMedia: (index) =>
		@cache.currentItem = parseInt(index)
		URL.update({item:index}, true)
		this.relayout()
		if URL.get("trailer") == "true"
			@uis.panel.opacity(0).css("z-index": 0)
		else
			@uis.panel.opacity(1).css("z-index": 11)


	setData: (data) =>
		params = URL.get()
		if params.item?
			this.show()
			page = Math.ceil(((params.item)/@OPTIONS.nbTiles)+0.1) - 1
			this.setPage(page)
			this.setMedia(params.item)

	toggleNavigation:  =>
		page = @cache.currentPage
		# hide/show navigation "< >"
		@uis.previous.opacity(1)
		@uis.next.opacity(1)
		if page == 0
			@uis.previous.opacity(0)
		if page >= Math.ceil((@cache.data.length / @OPTIONS.nbTiles)+0.1) - 1
			@uis.next.opacity(0)

	# show the given page in navigation, callback will be called after all the animations
	setPage: (page, callback=null) =>
		page  = parseInt(page)
		if page > @cache.data.length/@OPTIONS.nbTiles or page < 0 # limit of page
			return false
		if (not @cache.currentPage?) or (page != @cache.currentPage)
			start   = @OPTIONS.nbTiles * page
			tiles   = @uis.mediaContainer.find("li.actual")
			reverse = @cache.currentPage > page # -> effect for previous page clic
			@cache.currentPage = page
			# preload thumbnail and render the page
			thumbnail_to_preload = for _ in @cache.data[start..@OPTIONS.nbTiles - 1]
				_.thumbnail
			$.preload thumbnail_to_preload, =>
				# render
				tiles = @uis.mediaList.find("li.actual")
				i = 0
				interval  = setInterval (=>
					virtual_i = if reverse then @OPTIONS.nbTiles - 1 - i else i
					index     = start + virtual_i
					item      = @cache.data[index]
					nui       = $(tiles[virtual_i])
					if item?
						if (not nui? or nui.length < 1)
							nui = @uis.mediaTmpl.cloneTemplate()
							@uis.mediaList.append(nui)
						nui.removeClass "show hide"
						nui.find("a").attr("href", "#+item="+index)
						setTimeout (=>
							this.setThumbnail(virtual_i, nui, item.thumbnail)
						), 250 # fadeOut duration, time before we change the image and we fadeIn the tile
					else # there is no more image to show, so we hide previous image with animation
						if nui?
							nui.addClass "hide"
					i += 1
					if i >= @OPTIONS.nbTiles
						URL.enableLinks(@uis.mediaList)
						if callback?
							callback()
						setTimeout((=> this.toggleNavigation()), 250)
						clearInterval(interval)
				), 200 # time before each tile render

	setThumbnail: (index_in_page, nui, thumbnail_url) =>
		image = nui.find(".image")
		if this.setCurrentTileForVideo?
			this.setCurrentTileForVideo(index_in_page, nui)
		if image.prop("tagName") == "DIV"
			image.css("background-image", "url("+thumbnail_url+")")
		else if image.prop("tagName") == "IMG"
			image.attr("src", thumbnail_url)
		nui.addClass("show")

	next: =>
		this.setPage(@cache.currentPage + 1)

	previous: =>
		new_page = @cache.currentPage - 1
		if new_page < 0
			this.setPage(0)
		else
			this.setPage(new_page)

	show: =>
		super
		@uis.playerContainer.removeClass "hidden"
		@cache.isShown = true
		$(".FooterPanel").addClass("hidden")
		# back button
		$(".Page.links .back").removeClass("hidden").click((e) =>
			this.hide()
			e.preventDefault()).find("a").html($(".PageMenu .tile .wrapper").html())
		$("body").trigger("hidePanel")
		$('body').trigger("darkness", 0.7)
		@uis.next.removeClass("hidden")
		@uis.previous.removeClass("hidden")
		@backgroundWidget.suspend()
		$('body').trigger "hidePanelToggler"

	hide: =>
		super
		$(".Page.links .back").addClass("hidden")
		@backgroundWidget.restore()
		@ui.find(".player").addClass "hidden"
		@uis.playerContainer.addClass "hidden"
		URL.remove("item", true)
		@cache.isShown     = false
		@cache.currentPage = null
		@cache.currentItem = null
		$(".Panel").show()
		$('body').trigger("darkness", 0.3)
		$("body").trigger("setDirectPanelPage",URL.get("page"))
		@uis.mediaList.find("li.actual").remove()
		@uis.next.addClass("hidden")
		@uis.previous.addClass("hidden")
		$('body').trigger "showPanelToggler"
		if URL.get("trailer") == "true"
			URL.update({trailer:null, cat:"synopsis"})

# -----------------------------------------------------------------------------
#
# VIDEO PLAYER
#
# -----------------------------------------------------------------------------

class portfolio.VideoPlayer extends portfolio.MediaPlayer

	constructor: ->
		super
		@UIS = {
			playerContainer: ".videoPlayer"
			player         : ".videoPlayer iframe"
			panel          : ".mediaPanel"
			mediaContainer : ".mediaPanel .mediaContainer"
			mediaList      : ".mediaPanel .mediaContainer ul"
			mediaTmpl      : ".mediaPanel .media.template"
			close          : ".close"
			next           : ".next"
			previous       : ".previous"
			waiter         : ".waiter"
		}

	setData: (data) =>
		new_data = for d in data
			{thumbnail:d.thumbnail_small, media:d.id, ratio:d.width/d.height, duration:d.duration, title:d.title}
		@cache.data = new_data
		super()

	setMedia: (index) =>
		super
		# set the right video url to the iframe
		@uis.player.addClass("hidden").attr("src", "").attr("src", "http://player.vimeo.com/video/"+@cache.data[index].media+"?portrait=0&title=0&byline=0&autoplay=1")
		# show the loading animation after a given time
		animation = setTimeout (=> @uis.waiter.removeClass("hidden")), 750
		@uis.player.load =>
			clearTimeout(animation)
			@uis.player.removeClass("hidden")
			@uis.waiter.addClass("hidden")
		# select the good thumbnail
		index = @cache.currentItem
		page  = Math.ceil((index/@OPTIONS.nbTiles)+0.1) - 1
		if page == @cache.currentPage
			index_in_page = index % @OPTIONS.nbTiles
			li = $(@uis.mediaList.find("li.actual").removeClass("current")[index_in_page])
			li.addClass("current")
			info = Format.NumberFormat.SecondToString(@cache.data[index].duration)+"<br/>"+@cache.data[index].title
			li.find(".overlay").html(info)

	# if index match with current page and the given nui, set the 'current' class to nui and fill the overlay
	setCurrentTileForVideo: (index, nui) =>
		nui.removeClass("current")
		page_current_item  = Math.ceil((@cache.currentItem/@OPTIONS.nbTiles)+0.1) - 1
		if @cache.currentPage == page_current_item
			index_in_page = @cache.currentItem % @OPTIONS.nbTiles
			if index_in_page == index
				nui.addClass("current")
				info = Format.NumberFormat.SecondToString(@cache.data[@cache.currentItem].duration)+"<br/>"+@cache.data[@cache.currentItem].title
				nui.find(".overlay").html(info)

	hide: =>
		super
		@uis.player.attr("src", "")

# -----------------------------------------------------------------------------
#
# IMAGE PLAYER
#
# -----------------------------------------------------------------------------

class portfolio.ImagePlayer extends portfolio.MediaPlayer

	constructor: ->
		super
		@UIS = {
			playerContainer: ".imagePlayer"
			player         : ".imagePlayer .wrapper > img"
			panel          : ".mediaPanel"
			mediaContainer : ".mediaPanel .mediaContainer"
			mediaList      : ".mediaPanel .mediaContainer ul"
			mediaTmpl      : ".mediaPanel .media.template"
			close          : ".close"
			next           : ".next"
			previous       : ".previous"
			waiter         : ".waiter"
		}

	bindUI: (ui) =>
		super
		@uis.playerContainer.click (e) =>
			new_item = @cache.currentItem+1
			if new_item < @cache.data.length
				this.setMedia(new_item)
			else
				this.hide()
			e.preventDefault()
			return false

	setData: (data) =>
		new_data = for d in data
			{thumbnail:d.q, media:d.z}
		@cache.data = new_data
		super()

	setMedia: (index) =>
		super
		img = $("<img/>").attr("src", @cache.data[index].media)
		@uis.player.addClass("hidden")
		animation = setTimeout (=> @uis.waiter.removeClass("hidden")), 750
		img.load =>
			clearTimeout(animation)
			@uis.waiter.addClass("hidden")
			@uis.player.attr("src", @cache.data[index].media).removeClass("hidden")

	hide: =>
		super
		@uis.player.css("background-image", "")

# -----------------------------------------------------------------------------
#
# LANGUAGE
#
# -----------------------------------------------------------------------------

class portfolio.Language extends Widget

	constructor: ->
		@UIS = {
			languageTmpl : ".language.template"
		}

		@OPTIONS = {
			languages : ['en', 'fr', 'it']
		}

		@cache = {
			language : null
		}

	bindUI: (ui) =>
		super
		URL.enableLinks(@ui)
		URL.onStateChanged(this.onURLStateChanged)
		if URL.get("ln")
			@cache.language = URL.get("ln")
			this.toggle()
		else
			this.getLanguage()

	getLanguage: =>
		$.ajax("/api/getLanguage", {success : this.setData})

	setData: (data) =>

		@cache.language = data
		this.toggle()

	onURLStateChanged: =>
		if URL.hasChanged("ln") and URL.get("ln")
			$.ajax("/api/setLanguage/"+URL.get("ln"), {dataType: 'json', success : this.actualize})
		else
			this.toggle()

	actualize: =>
		document.location.reload(true)

	toggle: =>
		if @cache.language?
			other_languages = Utils.clone(@OPTIONS.languages)
			# exception for devil wich is in italian too
			if URL.get('project') != 'devil'
				other_languages.splice(other_languages.indexOf('it'), 1)
				if URL.get('ln') == 'it'
					URL.update({ln: 'en'})
					@cache.language = 'en'
			other_languages.splice(other_languages.indexOf(@cache.language), 1)
			@ui.find('.actual').remove()
			for other_language in other_languages
				nui = @uis.languageTmpl.cloneTemplate()
				nui.attr("href", "#+ln="+other_language)
				nui.text(other_language)
				@ui.append(nui)
			URL.enableLinks(@ui)
		else
			this.getLanguage()

# -----------------------------------------------------------------------------
#
# DOWNLOAD
#
# -----------------------------------------------------------------------------

class portfolio.Download extends Widget

	constructor: ->

		@UIS = {
			box      : ".box"
			password : "input[type=password]"
			error    : ".error"
		}

		@ACTIONS = ["getFile", "hide"]

	bindUI: (ui) =>
		super
		$(window).resize(this.relayout)
		this.relayout()

	relayout: =>
		window_height = $(window).height()
		box_height    = @uis.box.height()
		@uis.box.css({top:window_height/2 - box_height/2})

	getFile: =>
		kit_password = @uis.password.val()
		$.ajax("/api/download", {
			type     : "POST"
			data     : {password: kit_password}
			success  : this.sendFile
			error    : ((msg) => @uis.error.removeClass "hidden" )
		})

	sendFile: (data) =>
		@uis.error.addClass "hidden"
		this.hide()
		window.open(data,'Download')

$(window).load ()->
	if $.browser.msie and parseInt($.browser.version, 10)<9
		$("body > .wrap").addClass "hidden"
		$("body > .for-ie").removeClass "hidden"
	else
		$("body > .for-ie").addClass "hidden"
		$("body > .wrap").removeClass "hidden"
	Widget.bindAll()

# EOF