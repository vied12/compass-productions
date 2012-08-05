# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 04-Aug-2012
# -----------------------------------------------------------------------------

# import
Widget = window.serious.Widget

class TileManager extends Widget

	constructor: ->
		@UIS = {
			tilesList : ".tiles .tile", 
			tiles     : ".tiles"
		}

	bindUI: (ui) ->
		super
		@uis.tilesList.click (e) => this.tileSelected(e.target)

	tileSelected: (tile_selected) ->
		console.log @uis.tilesList[tile]
		for tile in @uis.tilesList when tile isnt tile_selected
			do =>
				tile = $(tile)
				console.log "aa", tile
				tile.addClass "closed"
				setTimeout(=> tile.addClass "hidden", 500)

new TileManager().bindUI(".tiles")



class VideoBackground extends Widget

	constructor: ->
		@UIS = {
			background : ".video-background"
			#body : "body"
		}		

	bindUI: (ui) ->
		super		
		@uis.background.videobackground
			videoSource: ['http://video.lesdebiles.com/05841.mp4']
			loop: true
			poster: 'http://serious-works.org/static/img/logo2.png'
		@uis.background.prepend "<div class='video-fx'></div>"
		#@uis['fx'] = $('.video-fx')

new VideoBackground().bindUI(".video-background")

# EOF
