# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 05-Aug-2012
# -----------------------------------------------------------------------------

Widget = window.serious.Widget

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
			currentLevel  : null
			currentTarget : null
		}
		
		@panel = new Panel().bindUI(".FooterPanel")
		# @background = new VideoBackground().bindUI(".video-background")

	setData: (data) =>
		@cache.data = data

	bindUI: (ui) =>
		super
		$.ajax("/api/data.json", {dataType: 'json', success : this.setData})
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement)) 
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)		
		$('body').bind  'cacheGallery', (e, project, gallery) => @.cacheProjectGallery(project, gallery)
		this.showMenu("main")


	tileSelected: (tile_selected) =>
		tile_selected = $(tile_selected)
		if tile_selected.hasClass "tile"
			target = tile_selected.attr "data-target"
			if target == "works"
				this.worksSelected()
			else if target == "news"
				this.newsSelected()
			else if target == "contact"
				this.contactSelected()
			else if @cache.currentTarget == "works"
				this.projectSelected(target)

	worksSelected: =>
		this.showMenu("works")
		@uis.worksTiles.removeClass "hidden"
			
	newsSelected: =>
		@uis.main.addClass "hidden"

	contactSelected: =>
		@uis.main.addClass "hidden"

	projectSelected: (project) =>
		if @uis.works.hasClass "focused"
			this.worksSelected()
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
		menu.removeClass "hidden"
		if @cache.currentTarget != null and @cache.currentTarget != name
			@ui.find("[data-name="+@cache.currentTarget+"]").addClass "hidden"
		@cache.currentTarget = name
		@cache.currentLevel  = parseInt(menu.attr("data-level"))

	back: =>
		$("body").trigger("projectUnselected")
		this.showMenu("main")

	getProjectByName: (name) =>
		for project in @cache.data.works
			if project.key == name
				return project

	cacheProjectGallery: (project, gallery) =>
		for cached_project in @cache.data.works
			if cached_project.key == project.key
				cached_project["gallery"] =  gallery



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
		@flickrGallery = new FlickrGallery("PROJECT_FLICKR_URL").bindUI(@ui.find ".gallery")
		$('body').bind 'projectSelected', (e, projet) => this.setProject(projet)
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"
			
		@uis.tabs.live("click", (e) => this.tabSelected(e.currentTarget or e.srcElement)) 
		$(window).resize(this.relayout)
		this.relayout()

	relayout: =>
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
		this.relayout()
		setTimeout((=> @uis.wrapper.addClass "hidden"), 250)

	open: =>
		@uis.wrapper.removeClass "hidden"
		@cache.isOpened = true
		@.tabSelected(@uis.wrapper.find('.tabs li:first'))
		this.relayout()

	setProject: (project) =>
		@flickrGallery.setPhotoSet("72157621752440028")
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


class FlickrGallery extends Widget

	constructor: (url) ->
		@OPTIONS = {

		}

		@UIS = {
			showMore    : ".more"
		}

	bindUI: (ui) =>
		super
		return this
		
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