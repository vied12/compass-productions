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
		# new VideoBackground().bindUI(".video-background")

	# setData: (data) =>
	# 	@cache.data = data
	# 	this.relayout()

	bindUI: (ui) =>
		super
		# $.ajax("/api/data.json", {dataType: 'json', success : this.setData})
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement)) 
		@uis.brandTile.live("click", this.back)
		$('body').bind('backToHome', this.back)
		this.showMenu("main")

	# relayout: =>
	# 	console.log , tile for tile in @cache.data.works

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
			$("body").trigger("projectSelected", projet)

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
		this.showMenu("main")

# -----------------------------------------------------------------------------
#
# VideoBackground
#
# -----------------------------------------------------------------------------

class VideoBackground extends Widget

	constructor: ->
		@UIS = {
			background : ".video-background"
		}		

	bindUI: (ui) ->
		super		
		@uis.background.videobackground
			videoSource: ['http://video.lesdebiles.com/05841.mp4']
			loop: true
			poster: 'http://serious-works.org/static/img/logo2.png'
		@uis.background.videobackground('mute')			
		@uis.background.prepend "<div class='video-fx'></div>"

# -----------------------------------------------------------------------------
#
# Panel
#
# -----------------------------------------------------------------------------

class Panel extends Widget

	constructor: (projet) ->
		@UIS = {
			panel   : ".FooterPanel"
			tabs    : ".FooterPanel .tabs"
			content : ".Footerpanel .content"
			close   : ".FooterPanel .close"
		}
		#@.buildMTabs()

	@cache = {
			synopsis   : null
			gallery    : null
			screenings : null
			credits    : null
		}

	bindUI: (ui) =>
		super
		$('body').bind 'projectSelected', (e, projet) => 
			this.load(projet)
		$('body').bind('projectUnselected', this.hide)
		@uis.close.click =>
			this.hide()
			$('body').trigger "backToHome"

	hide: =>
		@uis.panel.height("40px")
		@uis.panel.addClass "minimize"

	open: =>
		@uis.panel.removeClass "minimize"
		panelTop = $(window).height()-200
		@uis.panel.css "bottom", -panelTop
		@uis.panel.height(panelTop)
		@uis.panel.addClass "slideUp"
		#@uis.menus.live("click", (e) => @.menuSelected(e.target))

	load: (projet) ->
		this.open()

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	

new Navigation().bindUI(".Navigation")
# EOF
