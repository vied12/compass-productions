# -----------------------------------------------------------------------------
# Project : a Serious Project
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 04-Aug-2012
# -----------------------------------------------------------------------------

class Widget
	bindUI: (ui) ->
		@ui = $(ui)
		@uis = {}
		$.each @UIS, (key, value) =>
			@uis[key] = $(value)

window.serious = []
# register classes to a global variable
window.serious.Widget = Widget
# EOF
