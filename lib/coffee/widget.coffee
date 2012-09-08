# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 05-Sep-2012
# -----------------------------------------------------------------------------


class Widget
	bindUI: (ui) ->
		@ui = $(ui)
		@uis = {}
		if (typeof(@UIS) != "undefined")
			for key, value of @UIS
				nui = @ui.find(value)
				if nui.length < 1
					console.warn("uis", key, "not found in", ui)
				@uis[key] = nui

	set: (field, value) =>
		#TODO: use an instance variable to declare the fields list
		# to make selections operations at the begining
		@ui.find(".out[data-field="+field+"]").html(value)

class URL

	constructor: ->
		@previousHash = []
		@hash         = []
		@handlers     = []
		this.updateHash()
		$(window).hashchange( =>
			@previousHash = clone(@hash)
			this.updateHash()
			for handler in @handlers
				handler()
		)

	get: (field=null) =>
		if field
			return @hash[field]
		else
			return @hash

	onStateChanged: (handler) =>
		@handlers.push(handler)

	update: (fields, silent=false) =>
		hash = if silent then @hash else clone(@hash)
		for key, value of fields
			if isDefined(value)
				hash[key] = value
			else
				delete hash[key]
		this.updateUrl(hash)

	remove: (key, silent=false) =>
		hash = if silent then @hash else clone(@hash)
		if hash[key]
			delete hash[key]
		this.updateUrl(hash)

	hasChanged: (key) =>
		if isDefined(@hash[key])
			if isDefined(@previousHash[key])
				return @hash[key] != @previousHash[key]
			else
				return true
		return false

	hasBeenAdded: (key) =>
		console.error "not implemented"

	# update the @hash variable
	updateHash: (x) =>
		current_hash = location.hash
		current_hash = current_hash.split("&")
		@hash = []
		for hash in current_hash
			key_value = hash.split("=")
			# TODO: handle case length = 1
			if key_value.length == 2
				key   = key_value[0].replace("#", "")
				value = key_value[1].replace("#", "")
				@hash[key] = value
		return @hash

	# update the hash of url with the @hash variable content
	updateUrl: (hash=null) =>
		hash = hash or @hash
		new_hash = ""
		for key, value of hash
			new_hash += "&" + key + "=" + value
		location.hash = new_hash

isDefined = (obj) ->
	return typeof(obj) != 'undefined' and obj != null

jQuery.fn.cloneTemplate = (dict, fields) ->
	# fields is an optional parameter 
	# 	Only values from this list of fields are filled
	# 	If field don't match value in dict, associated template is removed
	#	Maybe a quicker option to remove all empty fields than select aposteriori all empty elements
	nui = $(this[0]).clone() 
	nui = nui.removeClass("template hidden").addClass("actual")
	if typeof(dict) == "object"
		if field?
			for klass in fields
				if dict[klass]?
					nui.find("."+klass).html(dict[klass])
				else
					nui.find("."+klass).remove() 
		else
			for klass, value of dict
				console.log "value", value
				if value != null
					nui.find("."+klass).html(value)
	return nui


clone = (obj) ->
	if not obj? or typeof obj isnt 'object'
		return obj
	if obj instanceof Date
		return new Date(obj.getTime()) 
	if obj instanceof RegExp
		flags = ''
		flags += 'g' if obj.global?
		flags += 'i' if obj.ignoreCase?
		flags += 'm' if obj.multiline?
		flags += 'y' if obj.sticky?
		return new RegExp(obj.source, flags) 
	newInstance = new obj.constructor()
	for key of obj
		newInstance[key] = clone obj[key]
	return newInstance

window.serious = []
# register classes to a global variable
window.serious.Widget = Widget
window.serious.URL    = URL
# EOF
