# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 12-Aug-2012
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
			tilesList        : ".Main .tile, .Works .tile",
			brandTile        : ".brand.tile",
			main             : ".Main",
			works            : ".Works",
			menus            : ".menu",
			worksTiles       : ".Works .tile"
			mainTiles        : ".Main .tile"
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
		$.ajax("/api/data.json", {dataType: 'json', success : this.setData})
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

	selectWorks: =>
		this.showMenu("works")
		@uis.worksTiles.removeClass("hidden")
			
	selectNews: =>
		@uis.main.addClass "hidden"

	selectContact: =>
		@uis.main.addClass "hidden"

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

		@UIS = {
			wrapper     : ".wrapper:first"
			tabs        : ".tabs"
			tabItems    : ".tabs li"
			tabContent  : ".tabContent"
			content     : ".content"
			close       : ".close"
		}

		@cache = {
			isOpened   : false
			currentTab : null
		}

	bindUI: (ui) =>
		super
		@flickrGallery = new FlickrGallery().bindUI(@ui.find ".gallery")
		$('body').bind 'projectSelected', (e, projet) => this.setProject(projet)
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"
		@uis.tabItems.live("click", (e) => this.tabSelected(e.currentTarget or e.srcElement)) 
		$(window).resize(=>(this.relayout(@cache.isOpened)))
		this.relayout(false)
		return this

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
			# @uis.content.jScrollPane({autoReinitialise:true})
		else
			top_offset = $(window).height()
			@ui.css({top : top_offset})

	hide: =>
		@cache.isOpened = false
		this.relayout(false)
		setTimeout((=> @uis.wrapper.addClass "hidden"), 100)

	open: =>
		@uis.wrapper.removeClass "hidden"
		@.tabSelected(@uis.wrapper.find('.tabs li:first'))
		this.relayout(true)
		# relayout the flickr widget after the opening animation
		setTimeout((=> @flickrGallery.relayout()), 500)

	setProject: (project) =>
		@uis.tabs.not('.gallery').empty()
		@ui.removeClass "hidden"
		@ui.find('.tabContent').not("[data-name=gallery]").remove()
		tabsStr = ""
		system_keys = ["key", "title", "email"]
		for k, v of project 
			if k not in system_keys
				tabsStr += "<li data-target=\"#{k}\">#{k}</li>"
				contentElements = ""
				switch k
					when "synopsis"	
						contentElements = v
					when "videos"
						for video in v
							contentElements += """
								<div class=\"content-item\">
									<iframe src="http://player.vimeo.com/video/#{video}" 
									width="500" 
									height="281" 
									frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>
								</div>
							"""
					else
						if typeof v == "string"
							contentElements = v
						else	
							for own content_k, contentElementValue of v
								contentItem=""
								contentElement=""
								if typeof contentElementValue == "object"
									for own kk, vv of contentElementValue
										switch kk
											when "article" then contentElement += "<article>#{vv}</article>"
											when "title"   then contentElement += "<h2>#{vv}</h2>"
											when "body"    then contentElement += "<p class=\"contentBody\">#{vv}</p>"
											when "date"    then contentElement += "<p class=\"contentDate\">#{vv}</p>"
											when "link"    then contentElement += "<a href=\"#{vv}\">#{contentElementValue["description"]}</a>"
								contentItem = "<div class=\"content-item\">#{contentElement}</div>"
								contentElements += contentItem
				tabContent = "<div data-name=\"#{k}\" class=\"tabContent hidden\">#{contentElements}</div>"
				if k != "gallery"
					@uis.content.append tabContent
		@uis.tabs.append(tabsStr)
		if project.gallery
			@flickrGallery.setPhotoSet(project.gallery)
		this.open()
		@uis.tabContent = @ui.find(@UIS.tabContent)

	tabSelected: (tab_selected) =>
		# content
		tab_selected = $(tab_selected)
		target       = tab_selected.attr "data-target"
		tab_content  = @uis.content.find("[data-name="+target+"]")
		@uis.tabContent.addClass "hidden"
		tab_content.removeClass "hidden"
		# tab
		@uis.tabs.find('li').removeClass "active"
		tab_selected.addClass "active"

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
			showMore    : ".show_more"
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
		
	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z/data.json", {dataType: 'json', success : this.setData})

	_makePhotoTile: (photoData) =>
		li = $('<li></li>')
		image = $('<img />').attr('src', photoData.q)
		link = $('<a></a>').attr('target', '_blank').attr('href', photoData.z)
		link.append image
		li.append link
		@uis.list.append li
		#put show more tile at the end:
		if @uis.list.find(".show_more")
			@uis.list.find(".show_more").appendTo @uis.list

	setData: (data) =>
		@uis.list.empty()
		@cache.data = data
		for photo, index in data[0..@OPTIONS.initial_quantity]
			@._makePhotoTile(photo)
		if data.length >= @OPTIONS.initial_quantity
			show_more_tile = $("<li class=\"show_more\">"+@OPTIONS.show_more_text+"</li>")
			@uis.list.append(show_more_tile)
			show_more_tile.click => @.showMore()
			@cache.photo_index = @OPTIONS.initial_quantity

	showMore: =>
		next_index = @cache.photo_index+@OPTIONS.initial_quantity
		if next_index >= @cache.data.length
			next_index = @cache.data.length	
			@ui.find(".show_more").addClass "hidden"
		for photo,index in @cache.data[@cache.photo_index+1..next_index]
			@._makePhotoTile(photo)
		@cache.photo_index = next_index

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	
new Navigation().bindUI(".Navigation")
# EOF