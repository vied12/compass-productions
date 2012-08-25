# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 23-Aug-2012
# -----------------------------------------------------------------------------

class Widget
	bindUI: (ui) ->
		@ui = $(ui)
		@uis = {}
		if (typeof(@UIS) != "undefined")
			for key, value of @UIS
				nui = @ui.find(value)
				if nui.length < 1
					console.error("uis", key, "not found in", ui)
				@uis[key] = nui

class URL
	constructor: ->
		@hash = []

	get: (fields) =>
		# TODO: permit the specify some fields
		return this.updateHash()

	update: (fields) =>
		this.updateHash()
		for key, value of fields
			@hash[key] = value
		this.updateUrl()

	remove: (key) =>
		this.updateHash()
		if @hash.key
			delete @hash[key]

	hasChanged: (key) =>
		console.error "not implemented"

	hasBeenAdded: (key) =>
		console.error "not implemented"

	# update the @hash variable
	updateHash: (x) =>
		current_hash = location.hash
		current_hash = current_hash.split("&")
		for hash in current_hash
			key_value = hash.split("=")
			# TODO: handle case length = 1
			if key_value.length == 2
				key   = key_value[0].replace("#", "")
				value = key_value[1].replace("#", "")
				@hash[key] = value
		return @hash

	# update the hash of url with the @hash variable content
	updateUrl: =>
		location.hash = ""
		for key, value of @hash
			location.hash += "&" + key + "=" + value

jQuery.fn.cloneTemplate = (dict) ->
	nui = $(this[0]).clone()
	nui = nui.removeClass("template hidden").addClass("actual")
	if typeof(dict) == "objet"
		for klass, value of dict
			nui.find("."+klass).html(value)s
	return nui

window.serious = []
# register classes to a global variable
window.serious.Widget = Widget
window.serious.URL    = URL
# EOF
