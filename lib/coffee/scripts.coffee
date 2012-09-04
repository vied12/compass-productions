# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 01-Sep-2012
# -----------------------------------------------------------------------------

Widget = window.serious.Widget
URL    = new window.serious.URL()
Format = window.serious.Format

# -----------------------------------------------------------------------------
#
# Navigation
#
# -----------------------------------------------------------------------------

class Navigation extends Widget

	constructor: ->
		@UIS = {
			tilesList        : ".Main .tile, .Works .tile"
			brandTile        : ".brand.tile"
			main             : ".Main"
			works            : ".Works"
			menus            : ".menu"
			worksTiles       : ".Works .tile"
			mainTiles        : ".Main .tile"
			pageLinks 		 : ".Page.links"
		}

		@CONFIG = {
			tileMargin : 4
		}

		@cache = {
			data           : null
			currentMenu    : null
			currentProject : null
			tileWidth      : null
		}

	bindUI: (ui) =>
		super
		@background = new Background().bindUI('.Background')
		@background.image("bg1.jpg")
		@background.video(["bg.mp4"])		
		@cache.tileWidth  = parseInt(@uis.tilesList.css("width"))
		$.ajax("/api/data", {dataType: 'json', success : this.setData})
		# binds events
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement))
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)
		# bind url change
		return this

	# set an absolute position for each tile. Usefull for animation
	relayout: (menu, template) =>
		offset_left = @cache.tileWidth + @CONFIG.tileMargin # 'cause of the first brand tile
		# Main Menu (layout horizontal)
		for tile, i in @uis.mainTiles
			left = offset_left + i * (@cache.tileWidth + @CONFIG.tileMargin)
			$(tile).css({left:left})
		# Works Menu (layout vertical, 3 tiles by column)
		x_iterator = 0
		for tile, i in @uis.worksTiles
			y_iterator = i%3
			top  = y_iterator * (@cache.tileWidth + @CONFIG.tileMargin)
			left = offset_left + x_iterator * (@cache.tileWidth + @CONFIG.tileMargin)
			$(tile).css({top:top, left:left})
			if i == 3 - 1
				x_iterator += 1
		# Navigation
		@ui.css("height", @cache.tileWidth)

	setData: (data) =>
		@cache.data = data
		@panel      = new Panel().bindUI(".FooterPanel") # needs to be instanciate before selectTile call
		# init from url
		params = URL.get()
		if params.project
			tile = params.project
		else
			tile = params.m or "main"
		this.selectTile(tile) # depends of @cache.data

	# trigger the good action with the given selected tile name
	selectTile: (tile) =>
		URL.update({m:tile})
		URL.remove("project")
		URL.remove("cat")
		# reset tile for fadding animation
		if tile in ["main", "news", "contact"]	
			@uis.tilesList.removeClass "show"
		# reset @cache.currentProject variable
		if @cache.currentProject and tile in ["main", "works", "news", "contact"]
			@cache.currentProject = null
		this.selectPageLink tile
		# Dispatch
		if tile == "main"
			console.log "main"
			this.showMenu("main")
		else if tile == "works"
			console.log "works"
			if not @cache.currentProject
				@uis.tilesList.removeClass "show"
			this.selectWorks()
		else if tile == "news"
			this.selectNews()
		else if tile == "contact"
			this.selectContact()
		else
			console.log "tile>>project"
			this.selectWorks()
			# FIXEME: check if given tile exists in data as a work
			this.selectProjet(tile)
			URL.update({project:tile, m:"works"})

	tileSelected: (tile_selected_ui) =>
		tile_selected_ui = $(tile_selected_ui)
		if tile_selected_ui.hasClass "tile"
			target = tile_selected_ui.attr "data-target"
			this.selectTile(target)

	selectPageLink: (tile) =>
		if tile == "main" 
			@uis.pageLinks.addClass "hide"
		else
			@uis.pageLinks.removeClass "hide"
			@uis.pageLinks.find("li").removeClass "active"
			@uis.pageLinks.find("."+tile).addClass "active"
			if tile in ["news","contact"]
				@uis.pageLinks.find('.menuRoot').addClass "hidden"
			else
				@uis.pageLinks.find('.menuRoot').removeClass "hidden"
				if tile != "works"
					@uis.pageLinks.find('.menuRoot').addClass "active"		

	selectWorks: =>
		this.showMenu("works")
		@uis.worksTiles.removeClass("hidden")
			
	selectNews: =>
		@uis.main.addClass "hidden"
		@uis.main.find('[data-target=news]').removeClass "hidden"
		$("body").trigger("setPanelPage", "news")


	selectContact: =>
		$("body").trigger("Contact.new")
		$("body").trigger("setPanelPage", "contact")

	selectProjet: (project) =>
		tile_selected = @uis.works.find("[data-target="+project+"]")
		# Hide all tiles, show selected tile
		@uis.worksTiles.addClass "hidden"
		tile_selected.removeClass "hidden"
		# Animation: set to first position
		tile_selected.css({
			top  : 0
			left : @cache.tileWidth + @CONFIG.tileMargin
		})
		# Get project's object and send it to panel
		project_obj = this.getProjectByName(project)
		$("body").trigger("projectSelected", project_obj)
		$("body").trigger("setPanelPage", "project")
		if(project_obj.backgroundImage)
			@background.image(project_obj.backgroundImage)		
		if(project_obj.backgroundVideos)
			console.log "sendDATA", project_obj.backgroundVideos
			@background.video(project_obj.backgroundVideos)
		@cache.currentProject = project

	# show the given menu, hide the previous opened menu
	showMenu: (name) =>
		this.relayout()
		menu = @ui.find "[data-name="+name+"]"
		if not menu.length > 0
			return false
		@ui.find(".menu").addClass "hidden"
		menu.removeClass "hidden"
		@cache.currentMenu = name
		# Animation, one by one, fadding effect
		i     = 0
		tiles = menu.find(".tile")
		interval = setInterval(=>
			$(tiles[i]).addClass("show")
			i += 1
			if i == tiles.length
				clearInterval(interval)
		, 50) # time between each iteration

	back: =>
		$("body").trigger("projectUnselected")
		if @cache.currentProject
			this.selectTile("works")
		else
			this.selectTile("main")

	getProjectByName: (name) =>
		for project in @cache.data.works
			if project.key == name
				return project

# -----------------------------------------------------------------------------
#
# Background
#
# -----------------------------------------------------------------------------

class Background extends Widget

	constructor: () ->
		@UIS = {
			backgrounds: "> :not(.mask)"
			image : "img"
			video : "video"
			mask: ".mask"
		}

		@CONFIG = {		
			imageUrl : "/static/images/"
			videoUrl : "/static/videos/"
			formats : {
				"mp4" : "avc1.4D401E, mp4a.40.2"
				"ogg" : "theora, vorbis"
				"webm" : "vp8.0, vorbis"
			}

		}

		@CACHE = {
			videoFormat : null 
		}

	endLoop: =>
		
	bindUI: (ui) ->
		super	
		$(window).resize(=>(this.relayout()))
		@uis.video.prop('muted', true)
		#@uis.video.prop('loop', 'loop')
		#Force Loop
		#@uis.video.bind("ended", => this.play())
		return this	

	relayout: =>
		this.resize(@uis.image, "auto")
		this.resize(@uis.video, "auto")
		this.resize(@uis.mask, "full")

	resize: (that, flexibleSize) =>
		if flexibleSize == "full"
			flexibleSize="100%"
		#ratio compliant
		view = "landscape" 
		if $(window).height() > $(window).width()
			view = "portrait"
		switch view
			when "landscape" 
				that.height(flexibleSize)
				that.width($(window).width())
			when "portrait"
				that.height($(window).height())
				that.width(flexibleSize)
		
	video: (data) =>
		@uis.backgrounds.addClass "hidden"
		#swap on image if playing video is not supported for format, 
		#use image's widget give better control on relayouting than poster attribute of <video>		
		canPlayFormat = this.getCompatibleVideoFormat()
		if canPlayFormat
			#look for the best file in config for this browser
			for file in data
				extension = file.split('.').pop()
				if extension == canPlayFormat
					#set source
					@uis.video.attr("src", @CONFIG.videoUrl+file)					
					@uis.video.removeClass "hidden"
					this.relayout(@uis.video)
					break
			if @uis.video.hasClass("hidden") == true
				@uis.image.removeClass "hidden"
		else
			@uis.image.removeClass "hidden"
				
	getCompatibleVideoFormat: () =>
		if @CACHE.videoFormat != null
			return @CACHE.videoFormat
		for format, codecs of @CONFIG.formats		
			source = 'video/'+format+'; codecs="'+codecs+'"'
			if @uis.video[0].canPlayType(source) 
				@CACHE.videoFormat = format
				return format
		return false
	
	image: (filename) =>
		@uis.backgrounds.addClass "hidden"
		@uis.image.attr("src", "static/images/#{filename}")
		#@uis.image.css("background-image", "url(/static/images/#{filename})")
		@uis.image.removeClass "hidden"
		this.relayout(@uis.image)



# -----------------------------------------------------------------------------
#
# Panel
#
# -----------------------------------------------------------------------------

    	
class Panel extends Widget

	constructor: (projet) ->

		@OPTIONS = {
			panelHeightClosed : 40
		}
		@PAGES = ["Project", "Contact", "News"]	
		@UIS = {
			wrapper     : ".wrapper:first"	
			content 	: ".pages"
			close       : ".close"
			pages 		: ".pages"
		}

		@cache = {
			isOpened    : false
			currentTab  : null
			currentPage : null
		}

	bindUI: (ui) =>
		super
		$('body').bind 'setPanelPage', (e, page) => this.goto page
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"
		$(window).resize(=>(this.relayout(@cache.isOpened)))
		# bind url change
		URL.onStateChanged( =>
			if URL.hasChanged("m")
				if m in @PAGES
					this.goto(URL.get("m"))
		)
		return this

	goto: (page) =>
		#refresh ui style
		for _page in @PAGES
			@ui.removeClass _page.toLowerCase()
		@ui.addClass page
		#close all pages
		@uis.wrapper.find('.page').removeClass "show"
		#show the one
		@uis.wrapper.find('.'+Format.Capitalize(page)).addClass "show"
		#open this panel
		this.open()
		#cache
		@cache.currentPage = page

	relayout: (open) =>
		@cache.isOpened = open
		if @cache.isOpened
			window_height = $(window).height()
			navigation_ui = $(".Navigation")
			# just under the navigation
			top_offset = navigation_ui.offset().top + navigation_ui.height()
			# 48 is the FooterBar height
			panel_height = window_height - top_offset - 48
			@ui.css({top:top_offset, height:panel_height})
			setTimeout((=> 
				@uis.content.css({height: window_height - @uis.content.offset().top - 80})
				), 500)
		else
			top_offset = $(window).height()
			@ui.css({top : top_offset})

	hide: =>
		@cache.isOpened = false
		this.relayout(false)
		setTimeout((=> @uis.wrapper.addClass "hidden"), 100)

	open: =>
		@ui.removeClass "hidden"
		@uis.wrapper.removeClass "hidden"
		this.relayout(true)

# -----------------------------------------------------------------------------
#
# Flickr Gallery
#
# -----------------------------------------------------------------------------

class FlickrGallery extends Widget

	constructor: (url) ->
		@OPTIONS = {
			initial_quantity   : 10
			show_more_quantity : 10
			show_more_text     : "More"
		}

		@UIS = {
			list        : ".photos"
			listItems   : ".photos li"
			showMore    : ".show_more.template"
		}

		@cache = {
			data        : null
			photo_index : null
		}

	bindUI: (ui) =>
		super
		return this
		
	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z", {dataType: 'json', success : this.setData})

	_makePhotoTile: (photoData) =>
		li    = $('<li></li>')
		image = $('<img />').attr('src', photoData.q)
		link  = $('<a></a>').attr('target', '_blank').attr('href', photoData.z)
		link.append image
		li.append link
		@uis.list.append li
		#put show more tile at the end:
		if @uis.list.find(".show_more")
			@uis.list.find(".show_more").appendTo @uis.list

	setData: (data) =>
		#clean old gallery
		@uis.list.find('li:not(.template)').remove()
		#update	cache data	
		@cache.data = data
		#make the first tiles 
		for photo, index in data[0..@OPTIONS.initial_quantity]
			this._makePhotoTile(photo)
		#show_more tile when more tile to show
		if data.length >= @OPTIONS.initial_quantity
			showMoreTile = @ui.find(".show_more.template").cloneTemplate()	
			showMoreTile.append @OPTIONS.show_more_text
			@uis.list.append(showMoreTile)
			showMoreTile.click => this.showMore()
			#update cache index
			@cache.photo_index = @OPTIONS.initial_quantity

	showMore: =>
		next_index = @cache.photo_index+@OPTIONS.initial_quantity
		if next_index >= @cache.data.length
			next_index = @cache.data.length	
			@ui.find(".show_more").addClass "hidden"
		for photo,index in @cache.data[@cache.photo_index+1..next_index]
			this._makePhotoTile(photo)
		@cache.photo_index = next_index

# -----------------------------------------------------------------------------
#
# News
#
# -----------------------------------------------------------------------------	

class News extends Widget

	constructor: (url) ->

		@UIS = {
			newsTmpl      : ".template"
			newsContainer : "ul"
		}

		@cache = {
			data : null
		}

	bindUI: (ui) =>
		super
		$.ajax("/api/news", {dataType: 'json', success : this.setData})	
		return this

	setData: (data) =>
		@cache.data = data
		for news in data
			nui = @uis.newsTmpl.cloneTemplate({
				title : news.title
				body  : news.content
				date  : news.date
			})
			@uis.newsContainer.append(nui)

# -----------------------------------------------------------------------------
#
# Contact
#
# -----------------------------------------------------------------------------

class Contact extends Widget

	constructor: (url) ->

		@OPTIONS = {
			textSuccess : "Thank You ! U got an answer ASAP"
			textFail 	: "Sorry"
		}

		@UIS = {
			slides 			: ".slide"
			home 			: ".home"
			form 			: "form"
			result 			: ".result"
			toFormLink 		: ".contactForm"
			buttonSend  	: ".submit"
		}

	bindUI: (ui) =>
		super
		$(window).resize(this.relayout)
		$('body').bind 'Contact.new', (e) => this.newContact()
		this.newContact()
		return this

	gotoSlide: (slide) =>
		@uis.slides.removeClass "show"
		slide.addClass "show"

	newContact: =>
		this.gotoSlide @uis.home
		@uis.toFormLink.click =>
			this.gotoSlide @uis.form

		@uis.buttonSend.click (e) =>
			e.preventDefault()
			dataString = 'email='+ @uis.form.find('[name=email]').value + '&message=' + @uis.form.find('[name=message]').value
			$.ajax("/api/contact", 
				{
				data: {
					email:		@uis.form.find('[name=email]').val(),
					message: 	@uis.form.find('[name=message]').val()
				},  
				dataType: 'json', 
				success : this.sentMessage})

			return false

	sentMessage: (success) =>
		this.gotoSlide @uis.result
		answer = @uis.result.find('p')
		if success
			answer.text @OPTIONS.textSuccess
		else
 			answer.text @OPTIONS.textFail
		
# -----------------------------------------------------------------------------
#
# Project
#
# -----------------------------------------------------------------------------	 

class Project extends Widget

	constructor: (project) ->

		@UIS = {
			tabs        : ".tabs"
			tabContent  : ".tabContent"
			tabContents : ".tabContents"
			tabTmpl     : ".tabs > li.template"		
		}
		@cache = {
			footerBarHeight : 0
		}
		@CATEGORIES    = ["synopsis", "screenings", "videos", "extra", "credits", "gallery", "press", "links"]	
		@flickrGallery = null

	bindUI: (ui) =>
		super
		@flickrGallery = new FlickrGallery().bindUI($(".tabContent.gallery"))
		# init from url
		params = URL.get()
		if params.project
			this.setProject(params.project)
		if params.cat
			this.selectTab(params.cat)
		# bind events
		$('body').bind 'projectSelected', (e, project) => 
			this.setProject(project)
			setTimeout((=>
				this.selectTab(URL.get("cat") or "synopsis")
			), 500) # fix before we find why @uis.tabContents.offset().top in relayout() is null
		# bind url change
		URL.onStateChanged(=>
			if URL.hasChanged("project")
				this.setProject(URL.get("project"))
			if URL.hasChanged("cat")
				this.selectTab(URL.get("cat"))
		)
		return this

	relayout: =>
		if @cache.footerBarHeight == 0
			@cache.footerBarHeight = $(".FooterBar").height()
		window_height    = $(window).height()
		offset_top       = @uis.tabContents.offset().top 
		if offset_top > 0
			container_height = window_height - offset_top - @cache.footerBarHeight
			@uis.tabContents.css("height", container_height)
			@uis.tabContents.jScrollPane({hideFocus:true})

	setProject: (project) =>
		this.setMenu(project)
		this.setContent(project)

	setMenu: (project) =>
		@uis.tabs.find('li:not(.template)').remove()
		system_keys = ["key", "email", "title"]
		for category, value of project
			if category in @CATEGORIES
				nui = @uis.tabTmpl.cloneTemplate()
				nui.find("a").text(category).attr("href", "#project="+project.key+"&cat="+category).attr("data-target", category)
				nui.attr("data-name", category)
				@uis.tabs.append(nui)

	setContent: (project) =>
		for category, value of project
			if category in @CATEGORIES
				nui = @uis.tabContents.find("[data-name="+category+"]")
				switch category
					when "synopsis"
						nui.find('p').html(value)
					when "videos"
						for video in value
							video_nui = nui.find(".template").cloneTemplate()
							video_nui.find('iframe').attr("src", "http://player.vimeo.com/video/"+video)
							nui.append(video_nui)
					when "gallery"
						@flickrGallery.setPhotoSet(project.gallery)
					when "press"
						for press in value
							press_nui = nui.find('.template').cloneTemplate(press)
							nui.append(press_nui)
					when "credits"
						for credit in value
							credit_nui = nui.find('.template').cloneTemplate(credit)
							nui.append(credit_nui)
					when "screenings" 
						for screening in value
							screening_nui = nui.find('.template').cloneTemplate(screening)
							nui.append(screening_nui)
					when "links"
						for link in value
							link_nui = nui.find(".template").cloneTemplate(link)
							nui.append(link_nui)

	selectTab: (category) =>
		tab_nui = @uis.tabContents.find("[data-name="+category+"]")
		@uis.tabContent.addClass "hidden"
		tab_nui.removeClass "hidden"
		tabs_nui = @uis.tabs.find("li").removeClass "active"
		@uis.tabs.find("[data-name="+category+"]").addClass "active"
		this.relayout()

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	
new Navigation().bindUI(".Navigation")
new News().bindUI(".News")
new Contact().bindUI(".Contact")
new Project().bindUI(".Project")
# EOF