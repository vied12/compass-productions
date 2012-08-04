class Widget
	bindUI: (ui) ->
		@ui = ui
		for i in @UIS
			do (i) ->
				alert i
		@uis = @ui.find("body")

class TileManager extends Widget
	@UIS = {
		tilesList : ".tile"
	}

	bindUI: ->
		super
		@uis.tilesList.click (e) -> 
			console.log "coucou", e


new TileManager().bindUI($(".tiles"))