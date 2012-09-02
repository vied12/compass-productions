# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 01-Sep-2012
# Last mod : 01-Sep-2012
# -----------------------------------------------------------------------------

class Format
	@Capitalize: (str) ->
		str.replace(/\w\S*/g, (txt) ->
			return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
		)

window.serious.Format = Format