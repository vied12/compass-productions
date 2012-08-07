/**
	* API "statique" minimaliste d'accès à l'API FlickR via JSONP.
	* Elle repose sur jQuery notamment pour les requêtes Ajax.
	* L'accès se fait par la méthode "interrogation()".
*/
var ApiFlickr = {

	/**
		* URL du service d'API FlickR.
		* @private
	*/
	_url_service: "http://api.flickr.com/services/rest/",
	
	/**
		* Paramètres par défaut de toutes les requêtes effectuées sur l'API.
		* Précisez votre propre "api_key" !
		* @private
	*/ 
	_parametres_requete_par_defaut: {
		'format': 'json',
		'api_key': 'VOTRE_API_KEY',
		'lang': 'fr-fr',
		'per_page': 5
	},
	
	/**
	 	* Chaîne de formatage d'une URL vers une image.
	 	* Les morceaux placés entre {...} seront remplacés par la fonction de templating.
	 */
	_format_url: "http://farm{farm}.static.flickr.com/{server}/{id}_{secret}{mstzb}.jpg",
	
	/**
	 	* Chaîne de formatage d'une URL vers une page où l'image est visible sur flickr.
  */
	_format_page: "http://www.flickr.com/photos/{owner}/{id}",
	
	
	
	
	/**
		* Interroger l'API Flickr. 
		* Il s'agit du point d'entrée "standard" pour utiliser cette classe.
		*
		* @param string methode à interroger sur l'API FlickR.
		* @param array paramètres complémentaires pour interroger l'API (optionnel)
	 	* @param function fonction de callback à appeler après exécution de la requête.
	*/
	interrogation: function(methode, parametres, callback) {
		if( typeof parametres == 'function' ) {
			callback = parametres;
			parametres = {};
		}
		this._requeter(
			jQuery.extend(parametres, {'method': methode}),
			callback
		);
	},
	
	/**
		* Générer une URL vers une photo à l'aide des informations récupérées
		* après interrogation de l'API.
		*
		* @param object objet "photo" retourné par l'API.
		* @param string format "flickr" souhaité pour l'image (optionnel).
		*
		* @return string l'URL vers l'image.
	*/
	url_photo: function(photo, taille) {
		// Si la taille a été précisée on ajoute un "_" pour respecter le format.
		photo.mstzb = (taille) ? '_' + taille : '';
		return this._f( this._format_url, photo );
	},
	
	/**
		* Générer une URL vers une page à l'aide des informations récupérées
		* après interrogation de l'API.
		*
		* @param object objet "photo" retourné par l'API.
		*
		* @return string l'URL vers la page flickr contenant l'image.
	*/
	url_page: function(photo) {
		return this._f( this._format_page, photo );
	},
	
	
	
	
	
	/**
	 	* Effectuer une requête sur l'API Flickr.
	 	* @private
	 	*
	 	* @param array paramètres complémentaires pour interroger l'API.
	 	* @param function fonction de callback à appeler après exécution de la requête.
  */
	_requeter: function(parametres, callback) {
		jQuery.ajax({
			url: this._url_service,
			type: 'get',
			data: jQuery.extend(this._parametres_requete_par_defaut, parametres),
			dataType: 'jsonp',
			jsonpCallback: 'jsonFlickrApi',
			success: function(donnees) {
				if(!donnees || donnees.stat != 'ok')
					throw donnees.message;
				callback.apply(this, arguments);
			}
		}); 
	},
	
	/**
		* Formater une chaîne en utilisant un objet de données, on effectue un 
		* remplacement en utilisant les clés du tableau vars pour faire la 
		* correspondance.
		* @private
		*
		* @param string chaîne à formater.
		* @param array tableau associatif des données à incorporer à la chaîne.
		* @return string la chaîne, enrichie avec les nouvelles données.
	*/
	_f: function( tpl, vars ) {
		var t = tpl;
		// Pour chacune des variables de l'objet de données, on effectue une 
		// recherche d'une entrée correspondant dans la chaîne.
		jQuery.each(vars, function(i, e) {
			var exp = new RegExp("\{"+i+"\}", 'g');
			t = t.replace(exp, e);
		});
		return t;
	} 
};