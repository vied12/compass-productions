# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 05-Oct-2012
# -----------------------------------------------------------------------------

window.serious = {}
window.serious.Utils  = {}

# -----------------------------------------------------------------------------
#
# UTILS
#
# -----------------------------------------------------------------------------	

isDefined = (obj) ->
	return typeof(obj) != 'undefined' and obj != null

jQuery.fn.opacity = (int) ->
	$(this).css({opacity:int})

window.serious.Utils.clone = (obj) ->
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
		newInstance[key] = window.serious.Utils.clone obj[key]
	return newInstance

jQuery.fn.cloneTemplate = (dict, removeUnusedField=false) ->
	# fields is an optional parameter 
	# 	Only values from this list of fields are filled
	# 	If field don't match value in dict, associated template is removed
	#	Maybe a quicker option to remove all empty fields than select aposteriori all empty elements
	nui = $(this[0]).clone()
	nui = nui.removeClass("template hidden").addClass("actual")
	if typeof(dict) == "object"
		for klass, value of dict
			if value != null
				nui.find(".out."+klass).html(value)
		if removeUnusedField
			nui.find(".out").each ->
				if $(this).html() == ""
					$(this).remove()
	return nui

Object.size = (obj) ->
	size = 0
	for key of obj
		if obj.hasOwnProperty(key)
			size++
	return size
# -----------------------------------------------------------------------------
#
# WIDGET
#
# -----------------------------------------------------------------------------	

class window.serious.Widget

	@bindAll = ->
		$(".widget").each(->
			Widget.ensureWidget($(this))
		)

	# return the Widget instance for the given selector
	@ensureWidget  = (ui) ->
		ui = $(ui)
		if ui[0]._widget?
			return ui[0]._widget
		else
			widget_class = Widget.getWidgetClass(ui)
			if widget_class?
				widget = new widget_class()
				widget.bindUI(ui)
				return widget
			else
				console.warn("widget not found for", ui)
				return null

	@getWidgetClass = (ui) ->
		return eval("(" + $(ui).attr("data-widget") + ")")

	bindUI: (ui) ->
		@ui = $(ui)
		if @ui[0]._widget
			delete @ui[0]._widget
		@ui[0]._widget = this # set widget in selector for ensureWidget
		@uis = {}
		# UIS
		if (typeof(@UIS) != "undefined")
			for key, value of @UIS
				nui = @ui.find(value)
				if nui.length < 1
					console.warn("uis", key, "not found in", ui)
				@uis[key] = nui
		# ACTIONS
		if @ACTIONS?
			for action in @ACTIONS
				@ui.find(".do[data-action=#{action}]").click (e) =>
					# TODO: Prevent overwriting
					action = $(e.currentTarget).attr("data-action")
					this[action]()
					e.preventDefault()

	set: (field, value) =>
		#TODO: use an instance variable to declare the fields list
		# to make selections operations at the begining
		@ui.find(".out[data-field="+field+"]", context).html(value)

	hide: =>
		@ui.addClass "hidden"

	show: =>
		@ui.removeClass "hidden"

# -----------------------------------------------------------------------------
#
# URL
#
# -----------------------------------------------------------------------------	

class window.serious.URL

	constructor: ->
		@previousHash = []
		@handlers     = []
		@hash         = this.fromString(location.hash)
		$(window).hashchange( =>
			@previousHash = window.serious.Utils.clone(@hash)
			@hash         = this.fromString(location.hash)
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

	set: (fields, silent=false) =>
		hash = if silent then @hash else window.serious.Utils.clone(@hash)
		hash = []
		for key, value of fields
			if isDefined(value)
				hash[key] = value
		this.updateUrl(hash)

	update: (fields, silent=false) =>
		hash = if silent then @hash else window.serious.Utils.clone(@hash)
		for key, value of fields
			if isDefined(value)
				hash[key] = value
			else
				delete hash[key]
		this.updateUrl(hash)

	remove: (key, silent=false) =>
		hash = if silent then @hash else window.serious.Utils.clone(@hash)
		if hash[key]
			delete hash[key]
		this.updateUrl(hash)

	hasChanged: (key) =>
		if @hash[key]?
			if @previousHash[key]?
				return @hash[key].toString() != @previousHash[key].toString()
			else
				return true
		else
			if @previousHash[key]?
				return true
		return false

	hasBeenAdded: (key) =>
		console.error "not implemented"

	# update the hash of url with the @hash variable content
	updateUrl: (hash=null) =>
		if not hash or Object.size(hash) == 0
			location.hash = '_'
		else
			location.hash = this.toString(hash)

	enableLinks: (context=null) =>
		$("a.internal[href]",context).click (e) =>
			link = $(e.currentTarget)
			href = link.attr("data-href") or link.attr("href")
			if href[0] == "#"
				if href.length > 1 and href[1] == "+"
					this.update(this.fromString(href[2..]))
				# FIXME: doesn't work, remove() doesn't take a list as parameter
				else if href.length > 1 and href[1] == "-"
					this.remove(this.fromString(href[2..]))
				else
					this.set(this.fromString(href[1..]))
			return false

	fromString: (value) =>
		value     = value or location.hash
		hash      = {}
		value     = value.replace('!', '')
		hash_list = value.split("&")
		for item in hash_list
			if item?
				key_value = item.split("=")
				# TODO: handle case length = 1
				if key_value.length == 2
					key   = key_value[0].replace("#", "")
					val = key_value[1].replace("#", "")
					hash[key] = val
		return hash

	toString: (hash_list=null) =>
		hash_list = hash_list or @hash
		new_hash = "!"
		i = 0
		for key, value of hash_list
			new_hash += "&" if i > 0
			new_hash += key + "=" + value
			i++
		return new_hash
# EOF
