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
		}

		@cache = {
			data          : null
			currentLevel  : null
			currentTarget : null
		}

	# setData: (data) =>
	# 	@cache.data = data
	# 	this.relayout()

	bindUI: (ui) =>
		super
		# $.ajax("/api/data.json", {dataType: 'json', success : this.setData})
		@uis.tilesList.live("click", (e) => this.tileSelected(e.target)) 
		@uis.brandTile.live("click", (e) => this.back())
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

	newsSelected: =>
		@uis.main.addClass "hidden"

	contactSelected: =>
		@uis.main.addClass "hidden"

	projectSelected: (projet) =>
		console.log "projectSelected", projet
		$("body").trigger("projectSelected", projet)

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
		@uis.background.prepend "<div class='video-fx'></div>"

		# @uis['fx'] = $('.video-fx')

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	

new Navigation().bindUI(".Navigation")
# new VideoBackground().bindUI(".video-background")

# EOF
