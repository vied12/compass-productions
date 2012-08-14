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
			worksTiles       : ".Works .tile"
		}

		@cache = {
			data          : null
			currentTarget : null
		}
		
		# @background = new VideoBackground().bindUI(".video-background")

	setData: (data) =>
		@cache.data = data
		@panel = new Panel().bindUI(".FooterPanel") # needs to be instanciate before selectTile call
		# init
		params = URL.get()
		tile = params.m or "main"
		this.selectTile(tile) # depends of @cache.data

	bindUI: (ui) =>
		super
		$.ajax("/api/data.json", {dataType: 'json', success : this.setData})
		# binds events
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement)) 
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)

	# trigger the good action with the given selected tile name
	selectTile: (tile) =>
		URL.update({m:tile})
		if tile == "main"
			this.showMenu("main")
		else if tile == "works"
			this.selectWorks()
		else if tile == "news"
			this.selectNews()
		else if tile == "contact"
			this.selectContact()
		else
			this.selectWorks()
			this.selectProjet(tile)

	tileSelected: (tile_selected_ui) =>
		tile_selected_ui = $(tile_selected_ui)
		if tile_selected_ui.hasClass "tile"
			target = tile_selected_ui.attr "data-target"
			this.selectTile(target)

	selectWorks: =>
		this.showMenu("works")
		@uis.worksTiles.removeClass "hidden"
			
	selectNews: =>
		@uis.main.addClass "hidden"

	selectContact: =>
		@uis.main.addClass "hidden"

	selectProjet: (project) =>
		if @uis.works.hasClass "focused"
			this.selectTile "works"
			@uis.works.removeClass "focused"
			$("body").trigger("projectUnselected")
		else
			@uis.works.addClass "focused"
			@uis.worksTiles.addClass "hidden"	
			@uis.works.find("[data-target="+project+"]").removeClass "hidden"
			project_obj = this.getProjectByName(project)
			$("body").trigger("projectSelected", project_obj)

	# show the given menu, hide the previous opened menu
	showMenu: (name) =>
		menu = @ui.find "[data-name="+name+"]"
		if not menu.length > 0
			return false
		@ui.find(".menu").addClass "hidden"
		menu.removeClass "hidden"
		@cache.currentTarget = name

	back: =>
		$("body").trigger("projectUnselected")
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
			videoSource: ['http://video.lesdebiles.com/05841.mp4']
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
			wrapper : ".wrapper:first"
			tabs    : ".tabs li"
			tabContents : ".tabContent"
			content : ".content"
			close   : ".close"
		}

		@cache = {
			isOpened : false
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
		@uis.tabs.live("click", (e) => this.tabSelected(e.currentTarget or e.srcElement)) 
		$(window).resize(this.relayout)
		this.relayout(false)
		return this

	relayout: (open=false) =>
		@cache.isOpened = open
		if @cache.isOpened
			window_height = $(window).height()
			navigation_ui = $(".Navigation")
			# just under the navigation
			top_offset = navigation_ui.offset().top + navigation_ui.height()
			@ui.css({top:top_offset, minHeight:window_height - top_offset})
		else
			top_offset = $(window).height() - @OPTIONS.panelHeightClosed
			@ui.css({top : top_offset})

	hide: =>
		@cache.isOpened = false
		this.relayout(false)
		setTimeout((=> @uis.wrapper.addClass "hidden"), 250)

	open: =>
		@uis.wrapper.removeClass "hidden"
		@.tabSelected(@uis.wrapper.find('.tabs li:first'))
		this.relayout(true)
		# relayout the flickr widget after the opening animation
		setTimeout((=> @flickrGallery.relayout()), 500)

	setProject: (project) =>
		if project.gallery
			@flickrGallery.setPhotoSet(project.gallery)
		@uis.content.find("[data-name=synopsis]").html(project.synopsis)
		@uis.content.find("[data-name=screenings]").html(project.screenings)
		@uis.content.find("[data-name=credits]").html(project.credits)
		this.open()

	tabSelected: (tab_selected) =>
		tab_selected = $(tab_selected)	
		target = tab_selected.attr "data-target"
		tabContent = @uis.content.find("[data-name="+target+"]")
		@uis.tabs.removeClass "active"
		tab_selected.addClass "active"
		@uis.content.find('.tabContent').removeClass "active"		
		tabContent.addClass "active"

# -----------------------------------------------------------------------------
#
# Flickr Gallery
#
# -----------------------------------------------------------------------------

class FlickrGallery extends Widget

	constructor: (url) ->
		@OPTIONS = {

		}

		@UIS = {
			showMore    : ".more"
		}

	bindUI: (ui) =>
		super
		this.relayout()
		$(window).resize(this.relayout)
		return this

	relayout: =>
		# set the height of the list, to show the scrollbar
		height = $(window).height() - @ui.offset().top
		@ui.css({height: height})
		
	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z/data.json", {dataType: 'json', success : this.setData})

	setData: (data) =>
		for photos in data
			li = $('<li></li>')
			image = $('<img />').attr('src', photos.q)
			link = $('<a></a>').attr('target', '_blank').attr('href', photos.z)     	
			link.append image
			li.append link
			@ui.append(li)

	showMore: =>
		log.console "more"

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	
new Navigation().bindUI(".Navigation")
# EOF