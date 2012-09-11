# -----------------------------------------------------------------------------
# Project : Portfolio - Compass Productions
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# Author : Olivier Chardin                                <jegrandis@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 04-Aug-2012
# Last mod : 10-Sep-2012
# -----------------------------------------------------------------------------
window.portfolio = {}

Widget = window.serious.Widget
URL    = new window.serious.URL()
Format = window.serious.Format
isMobile = window.serious.isMobile
# -----------------------------------------------------------------------------
#
# Navigation
#
# -----------------------------------------------------------------------------
class portfolio.Navigation extends Widget

	constructor: ->
		@UIS = {
			tilesList        : ".Main .tile, .Works .tile"
			brandTile        : ".brand.tile"
			main             : ".Main"
			works            : ".Works"
			page             :  ".PageMenu"
			menus            : ".menu"
			worksTiles       : ".Works .tile"
			mainTiles        : ".Main .tile"
			pageLinks 		 : ".Page.links"
		}

		@CONFIG = {
			tileMargin : 4
			pages      : ["project", "contact", "news"]
		}

		@cache = {
			currentMenu    : null
			currentPage    : null
		}
		@panelWidget   = null
		@projectWidget = null
		background     = null

	bindUI: (ui) =>
		super
		@panelWidget   = Widget.ensureWidget(".FooterPanel")
		@projectWidget = Widget.ensureWidget(".Project")
		@background    = Widget.ensureWidget(".Background")
		@background.image("bg1.jpg")
		#Add Mobile Class if necessary
		if isMobile.any()
			$('body').addClass "mobile"
		# binds events
		@uis.tilesList.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement))
		@uis.brandTile.live("click", (e) => this.tileSelected(e.currentTarget or e.srcElement))
		$('body').bind('backToHome', (e) => this.showMenu("main"))
		# bind url change
		URL.onStateChanged(=>
			if URL.hasChanged("menu")
				menu = URL.get("menu")
				if menu
					this.showMenu(menu)
			if URL.hasChanged("page")
				page = URL.get("page")
				if page
					this.showPage(page)
		)
		# init from url
		params = URL.get()
		if params.page
			this.showPage(params.page)		
		else if params.menu
			this.showMenu(params.menu)
		else
			this.showMenu("main")
		return this

	# show the given menu, hide the previous opened menu
	showMenu: (menu) =>	
		# hide panel if menu is not a page (i.e: work and main)
		if not (menu == "page")
			$("body").trigger("hidePanel")			
			this.selectPageLink(menu)
		else
			this.selectPageLink(@cache.currentPage)
		# show menu
		menu = @ui.find "[data-menu="+menu+"]"
		if not menu.length > 0
			return false
		@uis.menus.addClass "hidden"
		tiles = menu.find(".tile")
		tiles.addClass("no-animation").removeClass("show")
		menu.removeClass "hidden"
		# Animation, one by one, fadding effect
		i     = 0
		interval = setInterval(=>
			$(tiles[i]).removeClass("no-animation").addClass("show")
			i += 1
			if i == tiles.length
				clearInterval(interval)
		, 50) # time between each iteration		
		@cache.currentMenu = menu

	selectPageLink: (tile) =>
		if tile == "main" 
			@uis.pageLinks.addClass "hidden"
		else
			@uis.pageLinks.removeClass "hidden"
			@uis.pageLinks.find("li").removeClass "active"
			@uis.pageLinks.find(".#{tile}").addClass "active"
			menuRoot=@uis.pageLinks.find('.menuRoot')
			if tile in ["news","contact", "works"]
				menuRoot.addClass "hidden"
			else
				menuRoot.removeClass "hidden"
				if tile != "works"
					menuRoot.addClass "active"		

	showPage: (page) =>
		# set page menu (single tile)
		page_tile = @ui.find(".nav[data-target="+(URL.get("project") or page)+"]:first")
		@uis.page.html(page_tile.clone())
		@cache.currentPage = page
		this.showMenu("page")
		$("body").trigger("setPanelPage",page)

	tileSelected: (tile_selected_ui) =>
		tile_selected_ui = $(tile_selected_ui)
		if tile_selected_ui.hasClass "tile"
			target = tile_selected_ui.attr "data-target"
			# check if there is a menu for the current target
			if @ui.find("[data-menu="+target+"]").length > 0
				# FIXME: should not be here, cat and project are not on this widget
				URL.update({menu:target, page:null, project:null, cat:null})
			else # the target is a page
				if not (target in @CONFIG.pages)
					# project selected
					URL.update({page:"project", project:target, menu:null, cat:null})
				else
					URL.update({page:target, menu:null, project:null, cat:null})			

# -----------------------------------------------------------------------------
#
# Background
#
# -----------------------------------------------------------------------------

class portfolio.Background extends Widget

	constructor: ->
		@UIS = {
			backgrounds: "> :not(.mask)"
			image : ".image"
			video : "video.video"
			mask: ".mask"
		}

		@CONFIG = {
			imageUrl : "/static/images/"
			videoUrl : "/static/videos/"
			formats : {
				"mp4" : "avc1.4D401E, mp4a.40.2"
				"ogg" : "theora, vorbis"
				"webm" : "vp8.0, vorbis"
			}

		}

		@CACHE = {
			videoFormat : null 
			image : null
		}
		
	bindUI: (ui) ->
		super	
		$(window).resize(=>(this.relayout()))		
		$('body').bind "setVideos", (e, data) =>
				this.video(data.split(","))	
		$('body').bind("setNoVideo", => this.removeVideo())
		$('body').bind("setImage", (e, filename) => this.image(filename))
		return this	

	relayout: =>
		this.resize(@uis.image, "full")
		#crazy, video resizing seems to work properly without any help !
		#this.resize(@ui.find("video.actual"), "auto")
		this.resize(@uis.mask, "full")

	resize: (that, flexibleSize) =>	
		if flexibleSize == "full"
		 	flexibleSize="100%"
		aspectRatio = that.height() / that.width()
		#ratio compliant
		windowRatio = $(window).height() / $(window).width()
		if windowRatio > aspectRatio
			that.height($(window).height())
			that.width(flexibleSize)
		else
			that.height(flexibleSize)
			that.width($(window).width())
			
	removeVideo: =>
		@ui.find('.actual').remove()

	video: (data) =>
		#swap on image if playing video is not supported for format, 
		#use image's widget give better control on relayoupropting than poster attribute of <video>		
		@ui.find('.actual').remove()
		newVideo = @uis.video.cloneTemplate().addClass "hidden"
		newVideo.prop('muted', true)
		for file in data
			extension = file.split('.').pop()
			source=$('<source />').attr("src", @CONFIG.videoUrl+file)
			source.attr("type", "video/#{extension}")
			newVideo.append(source)
		if @CACHE.image != null
		 	newVideo.attr("poster", imageUrl+@CACHE.image)
		newVideo.on("canplaythrough", => newVideo.removeClass "hidden")
		@uis.video.after(newVideo)

	image: (filename) =>
		@ui.find('video.actual').addClass "hidden"
		@uis.image.css("background-image", "url(#{@CONFIG.imageUrl}#{filename})")
		@uis.image.removeClass "hidden"
		this.relayout(@uis.image)

# -----------------------------------------------------------------------------
#
# Panel
#
# -----------------------------------------------------------------------------
    	
class portfolio.Panel extends Widget

	constructor: ->

		@OPTIONS = {
			panelHeightClosed : 40
		}
		@PAGES = ["project", "contact", "news"]
		@UIS = {
			wrapper     : ".wrapper:first"	
			pages 		: ".pages"
			close       : ".close"
			contents 	: ".content"
		}

		@cache = {
			isOpened    : false
			currentTab  : null
			currentPage : null
			footerBarHeight : 0
			tilesHeight : null
		}

	bindUI: (ui) =>
		super
		$('body').bind 'setPanelPage', (e, page) => this.goto page
		$('body').bind('hidePanel', this.hide)
		$(window).resize(=>(this.relayout(@cache.isOpened)))
		return this	

	goto: (page) =>
		#close all pages
		@uis.wrapper.find('.page').removeClass "show"
		#show the one
		@uis.wrapper.find('.'+Format.Capitalize(page)).addClass "show"
		#open this panel
		this.open()
		#cache
		@cache.currentPage = page

	relayout: (open) =>
		@cache.isOpened = open
		if @cache.isOpened
			window_height = $(window).height()
			navigation_ui = $(".Navigation")
			# just under the navigation
			top_offset = navigation_ui.offset().top + navigation_ui.height() - 6
			@ui.css({top : top_offset})
			height = $(window).height() - 218
			if height > 0
				@ui.css({height : height})
		else
			top_offset = $(window).height()
			@ui.css({top : top_offset})

		setTimeout((=>$('body').trigger("relayoutContent")), 100)

	hide: =>
		@cache.isOpened = false
		this.relayout(false)
		setTimeout((=> @uis.wrapper.addClass "hidden"), 100)

	open: =>
		@ui.removeClass "hidden"
		@uis.wrapper.removeClass "hidden"
		this.relayout(true)

# -----------------------------------------------------------------------------
#
# Flickr Gallery
#
# -----------------------------------------------------------------------------

class portfolio.FlickrGallery extends Widget

	constructor: ->
		@OPTIONS = {
			initial_quantity   : 10
			show_more_quantity : 10
			show_more_text     : "More"
		}

		@UIS = {
			list        : ".photos"
			listItems   : ".photos li"
			showMore    : ".show_more.template"
		}

		@cache = {
			data        : null
			photo_index : null
		}

	bindUI: (ui) =>
		super
		return this
		
	setPhotoSet: (set_id) => $.ajax("/api/flickr/photosSet/"+set_id+"/qualities/q,z", {dataType: 'json', success : this.setData})

	_makePhotoTile: (photoData) =>
		li    = $('<li></li>')
		image = $('<img />').attr('src', photoData.q)
		link  = $('<a></a>').attr('target', '_blank').attr('href', photoData.z)
		link.append image
		li.append link
		@uis.list.append li
		#put show more tile at the end:
		if @uis.list.find(".show_more")
			@uis.list.find(".show_more").appendTo @uis.list

	setData: (data) =>
		#clean old gallery
		@uis.list.find('li:not(.template)').remove()
		#update	cache data	
		@cache.data = data
		#make the first tiles 
		for photo, index in data[0..@OPTIONS.initial_quantity]
			this._makePhotoTile(photo)
		#show_more tile when more tile to show
		if data.length >= @OPTIONS.initial_quantity
			showMoreTile = @ui.find(".show_more.template").cloneTemplate()	
			showMoreTile.append @OPTIONS.show_more_text
			@uis.list.append(showMoreTile)
			showMoreTile.click => this.showMore()
			#update cache index
			@cache.photo_index = @OPTIONS.initial_quantity

	showMore: =>
		next_index = @cache.photo_index+@OPTIONS.initial_quantity
		if next_index >= @cache.data.length
			next_index = @cache.data.length	
			@ui.find(".show_more").addClass "hidden"
		for photo,index in @cache.data[@cache.photo_index+1..next_index]
			this._makePhotoTile(photo)
		@cache.photo_index = next_index
		$('body').trigger "relayoutContent"

# -----------------------------------------------------------------------------
#
# News
#
# -----------------------------------------------------------------------------	

class portfolio.News extends Widget

	constructor: ->

		@UIS = {
			newsTmpl      : ".template"
			newsContainer : "ul"
			content       : ".content"
		}

		@cache = {
			data : null
		}

	bindUI: (ui) =>
		super
		$.ajax("/api/news/all", {dataType: 'json', success : this.setData})
		$("body").bind("relayoutContent", this.relayout)
		return this

	relayout: =>
		top_offset = $('.FooterPanel').height() - 80
		@ui.find(".content").css({height: top_offset}).jScrollPane({hideFocus:true})
		
	setData: (data) =>
		@cache.data = data
		for news in data
			console.log "news", news
			console.log "content", news.content
			date = new Date(news.date_creation)
			nui = @uis.newsTmpl.cloneTemplate({
				body:news.content
				date:date.toDateString()
			})
			nui.find(".title").append(news.title)
			@uis.newsContainer.append(nui)

# -----------------------------------------------------------------------------
#
# Contact
#
# -----------------------------------------------------------------------------

class portfolio.Contact extends Widget

	constructor: ->

		@UIS = {
			main        : ".main"
			form        : ".contactForm"
			email       : ".email"
			message     : ".message"
			results     : ".result"
			toFormLink  : ".toContactForm"
			buttonSend  : ".submit"
			errorMsg    : ".result.error"
			successMsg  : ".result.success"
		}

		@CONFIG = {
			minMessageHeight : 200
		}

	bindUI: (ui) =>
		super
		@uis.toFormLink.click((e) =>
			this.showForm()
			e.preventDefault()
		)
		@uis.buttonSend.click((e) =>
			e.preventDefault()
			this.sendMessage()
		)
		$('body').bind('relayoutContent', this.relayout)
		return this

	relayout: =>
		top_offset = $(".FooterPanel").height() - 80
		@ui.find(".content").css({height: top_offset}).jScrollPane({hideFocus:true,autoReinitialise:true})
		messageHeight = $(window).height() - @uis.message.offset().top - 190
		if messageHeight < @CONFIG.minMessageHeight
			messageHeight = @CONFIG.minMessageHeight
		@uis.message.css({height:messageHeight})


	showForm: =>
		@uis.form.removeClass "hidden"
		@uis.main.addClass "hidden"
		@uis.results.addClass "hidden"
		this.relayout()

	sendMessage: =>
		@uis.results.addClass "hidden"
		email   = @uis.form.find('[name=email]').val()
		message = @uis.form.find('[name=message]').val()
		$.ajax("/api/contact",
			{
				type: "POST"
				dataType: 'json'
				data: {email:email, message:message}
				success : ((msg)=>
					@uis.successMsg.removeClass "hidden"
				)
				error : ((msg)=>
					@uis.errorMsg.removeClass "hidden"
				)
			}
		)

# -----------------------------------------------------------------------------
#
# Project
#
# -----------------------------------------------------------------------------	 

class portfolio.Project extends Widget

	constructor: ->

		@UIS = {
			tabs        : ".tabs"
			tabContent  : ".content"
			tabContents : ".contents"
			tabTmpl     : ".tabs > li.template"		
		}
		@cache = {
			footerBarHeight : 0
			data            : null
		}
		@CATEGORIES    = ["synopsis", "screenings", "videos", "extra", "credits", "gallery", "press", "links"]	
		@flickrGallery = null
		@mediaPlayer   = null

	bindUI: (ui) =>
		super
		@flickrGallery = Widget.ensureWidget(".content.gallery")
		@mediaPlayer   = Widget.ensureWidget(".MediaPlayer")
		$.ajax("/api/data", {dataType: 'json', success : this.setData})
		# enable dynamic links (#+cat=...)
		URL.enableLinks(@ui)
		$("body").bind("relayoutContent", this.relayout)
		return this

	relayout: =>
		top_offset = $('.FooterPanel').height() - 100
		@ui.find(".content").css({height: top_offset}).jScrollPane({hideFocus:true})

	setData: (data) =>
		@cache.data = data
		# init from url
		params = URL.get()
		if params.project
			this.setProject(params.project)
			this.selectTab(URL.get("cat") or "synopsis")
		# bind url change
		URL.onStateChanged(=>
			if URL.hasChanged("project")
				if URL.get("project")?
					this.setProject(URL.get("project"))
					this.selectTab(URL.get("cat") or "synopsis")
			if URL.hasChanged("cat")
				if URL.get("cat")?
					this.selectTab(URL.get("cat"))
		)

	getProjectByName: (name) =>
		for project in @cache.data.works
			if project.key == name

				
				return project

	setProject: (project) =>
		project_obj = this.getProjectByName(project)
		this.setMenu(project_obj)
		this.setContent(project_obj)
		if project_obj.backgroundImage
			$('body').trigger("setImage", project_obj.backgroundImage)	
		if project_obj.backgroundVideos
			$('body').trigger("setVideos", ""+project_obj.backgroundVideos)
		else
			$('body').trigger("setNoVideo")

	setMenu: (project) =>
		@uis.tabs.find('li:not(.template)').remove()
		system_keys = ["key", "email", "title"]
		for category, value of project
			if category in @CATEGORIES
				nui = @uis.tabTmpl.cloneTemplate()
				nui.find("a").text(category).attr("href", "#+cat="+category).attr("data-target", category)
				nui.attr("data-name", category)
				@uis.tabs.append(nui)
		# update dynamic links
		URL.enableLinks(@uis.tabs)

	setContent: (project) =>
		for category, value of project
			if category in @CATEGORIES
				nui = @uis.tabContents.find("[data-name="+category+"] .wrapper")
				switch category
					when "synopsis"
						nui.find('p').html(value)
					when "videos"
						@mediaPlayer.setVideoData(value)
						list = nui.find("ul")
						# resets
						list.find("li:not(.template)").remove()
						for video, i in value
							video_nui = nui.find(".template").cloneTemplate()
							video_nui.find('img').attr("src", video.thumbnail_small)
							video_nui.find('a').attr("href", "#+video="+i)
							list.append(video_nui)
						# update dynamic links
						URL.enableLinks(list)
					when "gallery"
						@flickrGallery.setPhotoSet(project.gallery)
					when "press"
						for press in value
							press_nui = nui.find('.template').cloneTemplate(press)
							nui.append(press_nui)
					when "credits"
						for credit in value
							credit_nui = nui.find('.template').cloneTemplate(credit,true)
							nui.append(credit_nui)
					when "screenings" 
						for screening in value
							screening_nui = nui.find('.template').cloneTemplate(screening, true)
							nui.append(screening_nui)
					when "links"
						for link in value
							link_nui = nui.find(".template").cloneTemplate(link)
							link_nui.find('a').append(link.description)
							nui.append(link_nui)

	selectTab: (category) =>
		tab_nui = @uis.tabContents.find("[data-name="+category+"]")
		@uis.tabContent.addClass "hidden"
		tab_nui.removeClass "hidden"
		tabs_nui = @uis.tabs.find("li").removeClass "active"
		@uis.tabs.find("[data-name="+category+"]").addClass "active"
		this.relayout()

# -----------------------------------------------------------------------------
#
# MEDIA PLAYER
#
# -----------------------------------------------------------------------------	

class portfolio.MediaPlayer extends Widget

	constructor: ->
		@UIS = {
			player         : ".player"
			videoPlayer    : ".player .videoPlayer iframe"
			imagePlayer    : ".player .imagePlayer img"
			panel          : ".mediaPanel"
			mediaContainer : ".mediaPanel .mediaContainer"
			mediaList      : ".mediaPanel .mediaContainer ul"
			mediaTmpl      : ".mediaPanel .media.template"
			close          : ".close"
			next           : ".next"
			previous       : ".previous"
		}

		@OPTIONS = {
			nbTiles : 4
		}

		@cache = {
			data : null
			lastItem : 0
		}

	bindUI: (ui) =>
		super
		URL.onStateChanged =>
			if URL.hasChanged("video")
				if URL.get("video")
					this.show()
					this.setVideo(URL.get("video"))
					this.fillVideos(URL.get("video"))
				else
					this.hide()
		$(window).resize(this.relayout)
		@uis.close.click =>
			this.hide()
		@uis.next.click =>
			this.next()
		@uis.previous.click =>
			this.previous()

	relayout: =>
		player_height = @uis.panel.offset().top - 50
		player_width  = player_height * (16/9)
		@uis.videoPlayer.attr({height:player_height, width:player_width})
		@uis.player.css("width", player_width) # permit margin auto on player

	setVideoData: (videos) =>
		@cache.data = videos
		params = URL.get()
		if params.video?
			this.show()
			this.setVideo(params.video)
			this.removeAndFillVideos(params.video)

	removeAndFillVideos: (start=0) =>
		# Animation, one by one, fadding effect
		i = 0
		tiles = @uis.mediaContainer.find("li.actual")
		if tiles? and tiles.length > 0
			interval = setInterval(=>
				$(tiles[i]).removeClass("show")
				i += 1
				if i == tiles.length
					tiles.remove()
					this.fillVideos(start)
					clearInterval(interval)
			, 50) # time between each iteration
		else
			this.fillVideos(start)

	fillVideos: (start=0) =>s
		if @cache.data?
			videos = @cache.data[start..]
			if videos? and videos.length > 0
				for video, i in videos
					index = i + parseInt(start)
					nui = @uis.mediaTmpl.cloneTemplate()
					nui.find("a").attr("href", "#+video="+index)
					nui.find(".image").css({"background-image" : "url("+video.thumbnail_small+")"})
					@uis.mediaList.append(nui)
					@cache.lastItem = index
					if i >= @OPTIONS.nbTiles - 1
						break
				# Animation, one by one, fadding effect
				i = 0
				tiles = @uis.mediaContainer.find("li.actual")
				interval = setInterval(=>
					$(tiles[i]).addClass("show")
					i += 1
					if i == tiles.length
						clearInterval(interval)
				, 50) # time between each iteration	
				URL.enableLinks(@uis.mediaList)
		this.relayout()

	setVideo: (index) =>
		@uis.videoPlayer.attr("src", "http://player.vimeo.com/video/"+@cache.data[index].id+"?portrait=0&title=0&byline=0")

	next: =>
		this.removeAndFillVideos(@cache.lastItem+1)

	previous: =>
		new_index = @cache.lastItem - (@OPTIONS.nbTiles * 2) + 1
		if new_index < 0
			this.removeAndFillVideos(0)
		else
			this.removeAndFillVideos(new_index)

	show: =>
		super
		# move the tile under the brand tile
		@saveTileLeft =  $(".PageMenu").css("left")
		$(".PageMenu").css({left:0, top:@saveTileLeft})
		$("body").trigger("hidePanel")

	hide: =>
		super
		URL.remove("video", true)
		$(".PageMenu").css({left:@saveTileLeft, top:0})
		$("body").trigger("setPanelPage",URL.get("page"))

# -----------------------------------------------------------------------------
#
# Main
#
# -----------------------------------------------------------------------------	
Widget.bindAll()

# EOF