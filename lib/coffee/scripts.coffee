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
		@background = new VideoBackground().bindUI(".video-background")

	setData: (data) =>
		@cache.data = data

	bindUI: (ui) =>
		super
		$.ajax("/api/data.json", {dataType: 'json', success : this.setData})
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement)) 
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)
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

	projectSelected: (projet) =>
		if @uis.works.hasClass "focused"
			this.worksSelected()
			@uis.works.removeClass "focused"
			$("body").trigger("projectUnselected")
		else
			@uis.works.addClass "focused"
			@uis.worksTiles.addClass "hidden"	
			@uis.works.find("[data-target="+projet+"]").removeClass "hidden"
			project_obj = this.getProjectByName(projet)
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

		@CONFIG = {
			panelHeightClosed : 40
		}

		@UIS = {
			wrapper : ".wrapper:first"
			tabs    : ".tabs"
			content : ".content"
			close   : ".close"
		}

		@cache = {
			isOpened : false
		}

	bindUI: (ui) =>
		super
		$('body').bind 'projectSelected', (e, projet) => this.setProject(projet)
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"
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
			top_offset = $(window).height() - @CONFIG.panelHeightClosed
			@ui.css({top : top_offset})

	hide: =>
		@cache.isOpened = false
		this.relayout()
		setTimeout((=> @uis.wrapper.addClass "hidden"), 250)

	open: =>
		@uis.wrapper.removeClass "hidden"
		@cache.isOpened = true
		this.relayout()

	setProject: (project) =>
		# by exemple
		# @uis.title.html(projet.title)
		this.open()

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	

new Navigation().bindUI(".Navigation")
# EOF
