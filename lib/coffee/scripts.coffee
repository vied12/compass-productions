# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 29-Aug-2012
# -----------------------------------------------------------------------------

Widget = window.serious.Widget
URL    = new window.serious.URL()

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
		@background       = new VideoBackground().bindUI(".video-background")
		@cache.tileWidth  = parseInt(@uis.tilesList.css("width"))
		$.ajax("/api/data", {dataType: 'json', success : this.setData})
		# binds events
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement)) 
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)

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
		# init
		params = URL.get()
		tile   = params.m or "main"
		this.selectTile(tile) # depends of @cache.data

	# trigger the good action with the given selected tile name
	selectTile: (tile) =>
		URL.update({m:tile})
		# reset tile for fadding animation
		if tile in ["main", "news", "contact"]	
			@uis.tilesList.removeClass "show"
		# reset @cache.currentProject variable
		if @cache.currentProject and tile in ["main", "works", "news", "contact"]
			@cache.currentProject = null
		this.selectPageLink tile
		# Dispatch
		if tile == "main"
			this.showMenu("main")
		else if tile == "works"
			if not @cache.currentProject
				@uis.tilesList.removeClass "show"
			this.selectWorks()
		else if tile == "news"
			this.selectNews()
		else if tile == "contact"
			this.selectContact()
		else
			this.selectWorks()
			# FIXEME: check if given tile exists in data as a work
			this.selectProjet(tile)

	tileSelected: (tile_selected_ui) =>
		tile_selected_ui = $(tile_selected_ui)
		if tile_selected_ui.hasClass "tile"
			target = tile_selected_ui.attr "data-target"
			this.selectTile(target)

	selectPageLink: (tile) =>
		console.log "selectPageLink",  tile
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
		if @cache.currentProject
			return this.back()
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
# VideoBackground
#
# -----------------------------------------------------------------------------

class VideoBackground extends Widget

	bindUI: (ui) ->
		super		
		@ui.videobackground
			videoSource: ['http://vimeo.com/47569645/download?t=1345691328&v=112586909&s=d8b40a6ec2be36301c497849929dc443']
			loop: true
			poster: 'http://serious-works.org/static/img/logo2.png'
		@ui.videobackground('mute')			
		@ui.prepend "<div class='video-fx'></div>"

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
		@CATEGORIES = ["synopsis", "screening", "videos", "extra", "credits", "gallery", "press", "links"]	
		@UIS = {
			wrapper     : ".wrapper:first"
			tabs        : ".tabs"
			tabItems    : ".tabs li"
			tabContent  : ".tabContent"
			content     : ".tabContents"
			close       : ".close"
			tabTmpl     : ".tabs > li.template"
			pages 		: ".pages"
		}

		@cache = {
			isOpened   : false
			currentTab : null
			currentPage : null
		}

	bindUI: (ui) =>
		super
		@flickrGallery = new FlickrGallery().bindUI(@ui.find ".gallery")
		$('body').bind 'setPanelPage', (e, page) => this.setPage(page)
		$('body').bind 'projectSelected', (e, projet) => this.setPage("project", projet)
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"
		@uis.tabItems.live("click", (e) => this.tabSelected(e.currentTarget or e.srcElement)) 
		$(window).resize(=>(this.relayout(@cache.isOpened)))

		# bind url change
		$(window).hashchange( =>
			if URL.hasChanged("m")
				page = URL.get("m")
				this.setPage(page)
		)
		this.goto("project")
		this.relayout(false)
		return this
	
	setPage: (page, pageData) =>
		tabbedPage=['project']
		if page in tabbedPage 
			this.tabs(pageData)
		this.goto page
		this.open()

	capitalize: (str) ->
	    str.replace(/\w\S*/g, (txt) ->
	    	return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
	    	)

	goto: (page) =>
		#refresh ui style
		for _page in @PAGES
			@ui.removeClass _page
		@ui.addClass page
		#close all pages
		@uis.wrapper.find('.page').removeClass "show"
		#show the one
		@uis.wrapper.find('.'+this.capitalize(page)).addClass "show"
		#open this panel
		this.open()
		#cache
		@cache.currentPage = page

	tabSelected: (tab_selected) =>
		#console.log "select tab" , tab_selected
		# content
		tab_selected = $(tab_selected)
		console.log tab_selected.attr "data-target"
		target       = tab_selected.find('a').attr "data-target"
		tab_content  = @uis.content.find("[data-name="+target+"]")
		@uis.tabContent.addClass "hidden"
		tab_content.removeClass "hidden"
		# tab
		@uis.tabs.find('li').removeClass "active"
		tab_selected.addClass "active"

	tabs: (project) =>
		system_keys = ["key", "email", "title"]
		for category, value of project

			# Tab
			if category in @CATEGORIES
				nui = @uis.tabTmpl.cloneTemplate()
				nui.find("a").text(category).attr("href", "#cat="+category).attr("data-target", category)
				nui.find("a").click => this.tabSelected(category)
				@uis.tabs.append(nui)
				# Content
				this.tabcontent(category, value, project)

	tabcontent: (tabKey, tabData, project) =>
		#Fill Data for a specific tabContent
		#tabcontent element
		tabContent = @uis.content.find('.tabContent.' + tabKey)
		#refresh rendered div
		tabContent.find('.render').remove()
		render = $("<div>", {class: "render"})
		tabContent.append(render)
		switch tabKey
			when "synopsis"
				nui=@uis.content.find('.synopsis .template').cloneTemplate()
				nui.find('p').html(tabData)
				this.addContentElement(nui, render)			
			when "videos"
				nui=@uis.content.find('.videos .template').cloneTemplate()
				for  value in tabData
					nui.find('iframe').attr("src", "http://player.vimeo.com/video/"+value)
					this.addContentElement(nui, render)
			when "gallery"
				@flickrGallery.setPhotoSet(project.gallery)
			when "press" 
				for  value, key in tabData 
					nui=@uis.content.find('.press .template').cloneTemplate(value)
					this.addContentElement(nui, render)
			when "credits" 
				for  value, key in tabData 
					nui=@uis.content.find('.credits .template').cloneTemplate(value)
					this.addContentElement(nui, render)
			when "links" 
				nui = @uis.content.find('.links .template').cloneTemplate()
				for  value in tabData 
					nui.find('a').attr("href", value['link'])
					nui.find('a').text(value["description"])
					this.addContentElement(nui, render)
			when "extra" 
				nui = @uis.content.find('.extra .template').cloneTemplate()

	addContentElement: (ui, target) =>
		# Prepare and copy content element to render target
		nui_container = @ui.find('.tabContentElement.template').cloneTemplate()
		nui_container.append ui.html()
		target.append nui_container

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
			@uis.content.jScrollPane({autoReinitialise:true})
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
		@.tabSelected(@uis.wrapper.find('.tabs li:first'))
		this.relayout(true)
		# relayout the flickr widget after the opening animation
		setTimeout((=> @flickrGallery.relayout()), 500)


# -----------------------------------------------------------------------------
#
# Flickr Gallery
#
# -----------------------------------------------------------------------------

class FlickrGallery extends Widget

	constructor: (url) ->
		@OPTIONS = {
			initial_quantity : 10,
			show_more_quantity : 10
			show_more_text : "More"
		}

		@UIS = {
			list :	".photos"
			listItems : ".photos li"
			showMore    : ".show_more.template"
		}

		@cache = {
			data : null
			photo_index : null
		}

	bindUI: (ui) =>
		super
		this.relayout()
		$(window).resize(this.relayout)
		return this

	relayout: =>
		# set the height of the list, to show the scrollbar
		# height = $(window).height() - @ui.offset().top
		# @ui.css({height: height})
		
	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z", {dataType: 'json', success : this.setData})

	_makePhotoTile: (photoData) =>
		nui = @uis.list.find('.photos.template').cloneTemplate
		li = $('<li></li>')
		image = $('<img />').attr('src', photoData.q)
		link = $('<a></a>').attr('target', '_blank').attr('href', photoData.z)
		link.append image
		li.append link
		@uis.list.append li
		#put show more tile at the end:
		# TODO flickr
		if @uis.list.find(".show_more")
			@uis.list.find(".show_more").appendTo @uis.list

	setData: (data) =>
		nui = @uis.list
		#clean old_gallery
		@uis.list.find('li:not(.template)').remove()
		#update	cache data	
		@cache.data = data
		#make the first tiles 
		for photo, index in data[0..@OPTIONS.initial_quantity]
			this._makePhotoTile(photo)
		#show_more tile when more tile to show
		if data.length >= @OPTIONS.initial_quantity
			#create a dom element.
			showMoreTile = @ui.find(".show_more.template").cloneTemplate()	
			#show_more_tile.append @OPTIONS.show_more_text
			showMoreTile.append "ok"
			nui.append(showMoreTile)
			#an event for click show_more 
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
			slides : ".slide"
			home :	".home"
			form : "form"
			result : ".result"
			toFormLink : ".contactForm"
			button_send  : "button"
		}

	bindUI: (ui) =>
		super
		this.relayout()
		$(window).resize(this.relayout)
		$('body').bind 'Contact.new', (e) => this.newContact()
		this.newContact()
		return this

	relayout: =>
		#adapt form fields dimension
		console.log "relayout", @uis.form.find('textarea').height(), @ui.height() - 200
		#@uis.form.find('textarea').width( @ui.width() )	

	gotoSlide: (slide) =>
		@uis.slides.removeClass "show"
		slide.addClass "show"

	newContact: =>
		this.gotoSlide @uis.home
		@uis.slides.removeClass "show"
		@uis.home.addClass "show"
		@uis.toFormLink.click => this.gotoSlide @uis.form
		@uis.form.submit =>
			$.ajax("/api/contact", {type:'POST', dataType: 'json', success : this.sendMessage})

	sendMessage: (success) =>
		this.gotoSlide @uis.result
		answer = @uis.result.find('p')
		if success
			answer.text @OPTIONS.textSuccess
		else
 			answer.text @OPTIONS.textFail
			 
		


# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	
new Navigation().bindUI(".Navigation")
new News().bindUI(".News")
new Contact().bindUI(".Contact")
# EOF