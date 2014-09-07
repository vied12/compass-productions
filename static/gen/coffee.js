var Format, URL, Utils, Widget, isDefined,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.serious = {};

window.serious.Utils = {};

isDefined = function(obj) {
  return typeof obj !== 'undefined' && obj !== null;
};

jQuery.fn.opacity = function(int) {
  return $(this).css({
    opacity: int
  });
};

window.serious.Utils.clone = function(obj) {
  var flags, key, newInstance;
  if ((obj == null) || typeof obj !== 'object') {
    return obj;
  }
  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }
  if (obj instanceof RegExp) {
    flags = '';
    if (obj.global != null) {
      flags += 'g';
    }
    if (obj.ignoreCase != null) {
      flags += 'i';
    }
    if (obj.multiline != null) {
      flags += 'm';
    }
    if (obj.sticky != null) {
      flags += 'y';
    }
    return new RegExp(obj.source, flags);
  }
  newInstance = new obj.constructor();
  for (key in obj) {
    newInstance[key] = window.serious.Utils.clone(obj[key]);
  }
  return newInstance;
};

jQuery.fn.cloneTemplate = function(dict, removeUnusedField) {
  var klass, nui, value;
  if (removeUnusedField == null) {
    removeUnusedField = false;
  }
  nui = $(this[0]).clone();
  nui = nui.removeClass("template hidden").addClass("actual");
  if (typeof dict === "object") {
    for (klass in dict) {
      value = dict[klass];
      if (value !== null) {
        nui.find(".out." + klass).html(value);
      }
    }
    if (removeUnusedField) {
      nui.find(".out").each(function() {
        if ($(this).html() === "") {
          return $(this).remove();
        }
      });
    }
  }
  return nui;
};

Object.size = function(obj) {
  var key, size;
  size = 0;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      size++;
    }
  }
  return size;
};

window.serious.Widget = (function() {
  function Widget() {
    this.show = __bind(this.show, this);
    this.hide = __bind(this.hide, this);
    this.set = __bind(this.set, this);
  }

  Widget.bindAll = function() {
    return $(".widget").each(function() {
      return Widget.ensureWidget($(this));
    });
  };

  Widget.ensureWidget = function(ui) {
    var widget, widget_class;
    ui = $(ui);
    if (ui[0]._widget != null) {
      return ui[0]._widget;
    } else {
      widget_class = Widget.getWidgetClass(ui);
      if (widget_class != null) {
        widget = new widget_class();
        widget.bindUI(ui);
        return widget;
      } else {
        console.warn("widget not found for", ui);
        return null;
      }
    }
  };

  Widget.getWidgetClass = function(ui) {
    return eval("(" + $(ui).attr("data-widget") + ")");
  };

  Widget.prototype.bindUI = function(ui) {
    var action, key, nui, value, _i, _len, _ref, _ref1, _results;
    this.ui = $(ui);
    if (this.ui[0]._widget) {
      delete this.ui[0]._widget;
    }
    this.ui[0]._widget = this;
    this.uis = {};
    if (typeof this.UIS !== "undefined") {
      _ref = this.UIS;
      for (key in _ref) {
        value = _ref[key];
        nui = this.ui.find(value);
        if (nui.length < 1) {
          console.warn("uis", key, "not found in", ui);
        }
        this.uis[key] = nui;
      }
    }
    if (this.ACTIONS != null) {
      _ref1 = this.ACTIONS;
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        action = _ref1[_i];
        _results.push(this.ui.find(".do[data-action=" + action + "]").click((function(_this) {
          return function(e) {
            action = $(e.currentTarget).attr("data-action");
            _this[action]();
            return e.preventDefault();
          };
        })(this)));
      }
      return _results;
    }
  };

  Widget.prototype.set = function(field, value) {
    return this.ui.find(".out[data-field=" + field + "]", context).html(value);
  };

  Widget.prototype.hide = function() {
    return this.ui.addClass("hidden");
  };

  Widget.prototype.show = function() {
    return this.ui.removeClass("hidden");
  };

  return Widget;

})();

window.serious.URL = (function() {
  function URL() {
    this.toString = __bind(this.toString, this);
    this.fromString = __bind(this.fromString, this);
    this.enableLinks = __bind(this.enableLinks, this);
    this.updateUrl = __bind(this.updateUrl, this);
    this.hasBeenAdded = __bind(this.hasBeenAdded, this);
    this.hasChanged = __bind(this.hasChanged, this);
    this.remove = __bind(this.remove, this);
    this.update = __bind(this.update, this);
    this.set = __bind(this.set, this);
    this.onStateChanged = __bind(this.onStateChanged, this);
    this.get = __bind(this.get, this);
    this.previousHash = [];
    this.handlers = [];
    this.hash = this.fromString(location.hash);
    $(window).hashchange((function(_this) {
      return function() {
        var handler, _i, _len, _ref, _results;
        _this.previousHash = window.serious.Utils.clone(_this.hash);
        _this.hash = _this.fromString(location.hash);
        _ref = _this.handlers;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          handler = _ref[_i];
          _results.push(handler());
        }
        return _results;
      };
    })(this));
  }

  URL.prototype.get = function(field) {
    if (field == null) {
      field = null;
    }
    if (field) {
      return this.hash[field];
    } else {
      return this.hash;
    }
  };

  URL.prototype.onStateChanged = function(handler) {
    return this.handlers.push(handler);
  };

  URL.prototype.set = function(fields, silent) {
    var hash, key, value;
    if (silent == null) {
      silent = false;
    }
    hash = silent ? this.hash : window.serious.Utils.clone(this.hash);
    hash = [];
    for (key in fields) {
      value = fields[key];
      if (isDefined(value)) {
        hash[key] = value;
      }
    }
    return this.updateUrl(hash);
  };

  URL.prototype.update = function(fields, silent) {
    var hash, key, value;
    if (silent == null) {
      silent = false;
    }
    hash = silent ? this.hash : window.serious.Utils.clone(this.hash);
    for (key in fields) {
      value = fields[key];
      if (isDefined(value)) {
        hash[key] = value;
      } else {
        delete hash[key];
      }
    }
    return this.updateUrl(hash);
  };

  URL.prototype.remove = function(key, silent) {
    var hash;
    if (silent == null) {
      silent = false;
    }
    hash = silent ? this.hash : window.serious.Utils.clone(this.hash);
    if (hash[key]) {
      delete hash[key];
    }
    return this.updateUrl(hash);
  };

  URL.prototype.hasChanged = function(key) {
    if (this.hash[key] != null) {
      if (this.previousHash[key] != null) {
        return this.hash[key].toString() !== this.previousHash[key].toString();
      } else {
        return true;
      }
    } else {
      if (this.previousHash[key] != null) {
        return true;
      }
    }
    return false;
  };

  URL.prototype.hasBeenAdded = function(key) {
    return console.error("not implemented");
  };

  URL.prototype.updateUrl = function(hash) {
    if (hash == null) {
      hash = null;
    }
    if (!hash || Object.size(hash) === 0) {
      return location.hash = '_';
    } else {
      return location.hash = this.toString(hash);
    }
  };

  URL.prototype.enableLinks = function(context) {
    if (context == null) {
      context = null;
    }
    return $("a.internal[href]", context).click((function(_this) {
      return function(e) {
        var href, link;
        link = $(e.currentTarget);
        href = link.attr("data-href") || link.attr("href");
        if (href[0] === "#") {
          if (href.length > 1 && href[1] === "+") {
            _this.update(_this.fromString(href.slice(2)));
          } else if (href.length > 1 && href[1] === "-") {
            _this.remove(_this.fromString(href.slice(2)));
          } else {
            _this.set(_this.fromString(href.slice(1)));
          }
        }
        return false;
      };
    })(this));
  };

  URL.prototype.fromString = function(value) {
    var hash, hash_list, item, key, key_value, val, _i, _len;
    value = value || location.hash;
    hash = {};
    value = value.replace('!', '');
    hash_list = value.split("&");
    for (_i = 0, _len = hash_list.length; _i < _len; _i++) {
      item = hash_list[_i];
      if (item != null) {
        key_value = item.split("=");
        if (key_value.length === 2) {
          key = key_value[0].replace("#", "");
          val = key_value[1].replace("#", "");
          hash[key] = val;
        }
      }
    }
    return hash;
  };

  URL.prototype.toString = function(hash_list) {
    var i, key, new_hash, value;
    if (hash_list == null) {
      hash_list = null;
    }
    hash_list = hash_list || this.hash;
    new_hash = "!";
    i = 0;
    for (key in hash_list) {
      value = hash_list[key];
      if (i > 0) {
        new_hash += "&";
      }
      new_hash += key + "=" + value;
      i++;
    }
    return new_hash;
  };

  return URL;

})();

window.serious.format = {};

serious.format.StringFormat = (function() {
  function StringFormat() {}

  StringFormat.Capitalize = function(str) {
    if ((str != null) && str !== "") {
      return str.replace(/\w\S*/g, function(txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
      });
    } else {
      return null;
    }
  };

  return StringFormat;

})();

serious.format.NumberFormat = (function() {
  function NumberFormat() {}

  NumberFormat.SecondToString = function(seconds) {
    var hours, minutes;
    hours = parseInt(seconds / 3600) % 24;
    minutes = parseInt(seconds / 60) % 60;
    seconds = parseInt(seconds % 60, 10);
    if (hours < 10) {
      hours = "0" + hours;
    }
    if (minutes < 10) {
      minutes = "0" + minutes;
    }
    if (seconds < 10) {
      seconds = "0" + seconds;
    }
    if (hours === "00") {
      return minutes + ":" + seconds;
    } else {
      return hours + ":" + minutes + ":" + seconds;
    }
  };

  return NumberFormat;

})();

window.portfolio = {};

Widget = window.serious.Widget;

URL = new window.serious.URL();

Format = window.serious.format;

Utils = window.serious.Utils;

portfolio.Navigation = (function(_super) {
  __extends(Navigation, _super);

  function Navigation() {
    this.tileSelected = __bind(this.tileSelected, this);
    this.showPage = __bind(this.showPage, this);
    this.updatePanelMenuRoot = __bind(this.updatePanelMenuRoot, this);
    this.updatePanelMenu = __bind(this.updatePanelMenu, this);
    this.selectPageLink = __bind(this.selectPageLink, this);
    this.showMenu = __bind(this.showMenu, this);
    this.bindUI = __bind(this.bindUI, this);
    var background;
    this.UIS = {
      tilesList: ".Main .tile, .Works .tile",
      brandTile: ".brand.tile",
      main: ".Main",
      works: ".Works",
      page: ".PageMenu",
      menus: ".menu",
      worksTiles: ".Works .tile",
      mainTiles: ".Main .tile",
      pageLinks: ".Page.links",
      menuRoot: ".Page.links .menuRoot",
      promo: ".promo"
    };
    this.CONFIG = {
      tileMargin: 4,
      pages: ["project", "contact", "news"]
    };
    this.cache = {
      currentMenu: null,
      currentPage: null
    };
    this.panelWidget = null;
    this.projectWidget = null;
    background = null;
  }

  Navigation.prototype.bindUI = function(ui) {
    var params;
    Navigation.__super__.bindUI.apply(this, arguments);
    this.panelWidget = Widget.ensureWidget(".FooterPanel");
    this.projectWidget = Widget.ensureWidget(".Project");
    this.background = Widget.ensureWidget(".Background");
    this.uis.tilesList.live("click", (function(_this) {
      return function(e) {
        return _this.tileSelected(e.currentTarget || e.srcElement);
      };
    })(this));
    this.uis.brandTile.live("click", (function(_this) {
      return function(e) {
        return _this.tileSelected(e.currentTarget || e.srcElement);
      };
    })(this));
    $('body').bind('backToHome', (function(_this) {
      return function(e) {
        return _this.showMenu("main");
      };
    })(this));
    $('body').bind('updatePanelMenuRoot', (function(_this) {
      return function(e, opened) {
        return _this.updatePanelMenuRoot(opened);
      };
    })(this));
    $('body').bind('desactivatelPanelToggler', (function(_this) {
      return function(e, opened) {
        return _this.uis.menuRoot.addClass("hidden");
      };
    })(this));
    $('body').bind('activatelPanelToggler', (function(_this) {
      return function(e, opened) {
        return _this.uis.menuRoot.removeClass("hidden");
      };
    })(this));
    URL.onStateChanged((function(_this) {
      return function() {
        var menu, page;
        if (URL.hasChanged("menu")) {
          menu = URL.get("menu");
          if (menu) {
            _this.showMenu(menu);
          }
        }
        if (URL.hasChanged("page")) {
          page = URL.get("page");
          if (page) {
            _this.showPage(page);
            return $('body').trigger("currentPage", page);
          }
        }
      };
    })(this));
    params = URL.get();
    if (params.page != null) {
      this.showPage(params.page);
    } else if (params.menu != null) {
      this.showMenu(params.menu);
    } else {
      this.showMenu("main");
    }
    this.uis.tilesList.mouseover((function(_this) {
      return function(e) {
        return _this.uis.tilesList.addClass("highlighted").filter(e.currentTarget).removeClass("highlighted");
      };
    })(this)).mouseout((function(_this) {
      return function(e) {
        return _this.uis.tilesList.removeClass("highlighted");
      };
    })(this));
    return this;
  };

  Navigation.prototype.showMenu = function(menu) {
    var i, interval, tiles;
    if (menu === "main") {
      this.background.darkness(0);
      this.uis.promo.removeClass("hidden");
      this.background.resetClass();
      this.background.image("index_bg.jpg", true);
      $('body').trigger("setNoVideo");
      $('body').trigger("cancelDelayedPanel");
    } else {
      this.uis.promo.addClass("hidden");
    }
    if (!(menu === "page")) {
      $("body").trigger("hidePanel");
      this.selectPageLink(menu);
    } else {
      this.selectPageLink(this.cache.currentPage);
    }
    if (menu === "main" || menu === "works") {
      this.uis.menuRoot.addClass("hidden");
    }
    menu = this.ui.find("[data-menu=" + menu + "]");
    if (!menu.length > 0) {
      return false;
    }
    this.uis.menus.addClass("hidden");
    tiles = menu.find(".tile");
    tiles.addClass("no-animation").removeClass("show");
    menu.removeClass("hidden");
    i = 0;
    interval = setInterval((function(_this) {
      return function() {
        $(tiles[i]).removeClass("no-animation").addClass("show");
        i += 1;
        if (i === tiles.length) {
          return clearInterval(interval);
        }
      };
    })(this), 50);
    return this.cache.currentMenu = menu;
  };

  Navigation.prototype.selectPageLink = function(tile) {
    if (tile === "main") {
      return this.uis.pageLinks.addClass("hidden");
    } else {
      this.uis.pageLinks.removeClass("hidden");
      this.uis.pageLinks.find("li").removeClass("active");
      this.uis.pageLinks.find("." + tile).addClass("active");
      this.uis.menuRoot.removeClass("hidden");
      if (tile !== "works") {
        return this.uis.menuRoot.click((function(_this) {
          return function(e) {
            e.preventDefault();
            return _this.updatePanelMenu();
          };
        })(this));
      }
    }
  };

  Navigation.prototype.updatePanelMenu = function() {
    if (!this.panelWidget.isOpened()) {
      return setTimeout(((function(_this) {
        return function() {
          return _this.panelWidget.open();
        };
      })(this)), 100);
    } else {
      return setTimeout(((function(_this) {
        return function() {
          return _this.panelWidget.hide();
        };
      })(this)), 100);
    }
  };

  Navigation.prototype.updatePanelMenuRoot = function(opened) {
    if (opened) {
      this.uis.menuRoot.addClass("hidden");
      if (!this.uis.menuRoot.hasClass("active")) {
        return this.uis.menuRoot.addClass("active");
      }
    } else {
      this.uis.menuRoot.removeClass("hidden");
      return this.uis.menuRoot.removeClass("active");
    }
  };

  Navigation.prototype.showPage = function(page) {
    var page_tile;
    page_tile = this.ui.find(".nav[data-target=" + (URL.get("project") || page) + "]:first");
    this.uis.page.html(page_tile.clone());
    this.cache.currentPage = page;
    this.showMenu("page");
    if (URL.get("cat") != null) {
      return $("body").trigger("setDirectPanelPage", page);
    } else {
      return $("body").trigger("setPanelPage", page);
    }
  };

  Navigation.prototype.tileSelected = function(tile_selected_ui) {
    var target;
    tile_selected_ui = $(tile_selected_ui);
    if (tile_selected_ui.hasClass("tile")) {
      target = tile_selected_ui.attr("data-target");
      if (this.ui.find("[data-menu=" + target + "]").length > 0) {
        return URL.update({
          menu: target,
          page: null,
          project: null,
          cat: null
        });
      } else {
        if (!(__indexOf.call(this.CONFIG.pages, target) >= 0)) {
          return URL.update({
            page: "project",
            project: target,
            menu: null,
            cat: null
          });
        } else {
          return URL.update({
            page: target,
            menu: null,
            project: null,
            cat: null
          });
        }
      }
    }
  };

  return Navigation;

})(Widget);

portfolio.Background = (function(_super) {
  __extends(Background, _super);

  function Background() {
    this.resetClass = __bind(this.resetClass, this);
    this.darkness = __bind(this.darkness, this);
    this.image = __bind(this.image, this);
    this.video = __bind(this.video, this);
    this.removeVideo = __bind(this.removeVideo, this);
    this.restore = __bind(this.restore, this);
    this.suspend = __bind(this.suspend, this);
    this.setProject = __bind(this.setProject, this);
    this.relayout = __bind(this.relayout, this);
    this.UIS = {
      image: ".image.template",
      video: ".video",
      mask: ".mask",
      darkness: ".darkness",
      mousemask: ".mousemask"
    };
    this.CONFIG = {
      imageUrl: "/static/images/",
      videoUrl: "/static/videos/"
    };
    this.CACHE = {
      image: null,
      suspended: false
    };
  }

  Background.prototype.bindUI = function(ui) {
    Background.__super__.bindUI.apply(this, arguments);
    $(window).resize((function(_this) {
      return function() {
        return _this.relayout();
      };
    })(this));
    $('body').bind("setVideos", (function(_this) {
      return function(e, data) {
        return _this.video(data.split(","));
      };
    })(this));
    $('body').bind("setNoVideo", (function(_this) {
      return function() {
        return _this.removeVideo();
      };
    })(this));
    $('body').bind("setImage", (function(_this) {
      return function(e, filename) {
        return _this.image(filename);
      };
    })(this));
    $('body').bind("darkness", (function(_this) {
      return function(e, darkness) {
        return _this.darkness(darkness);
      };
    })(this));
    $('body').bind("suspendBackground", (function(_this) {
      return function(e) {
        return _this.suspend();
      };
    })(this));
    $('body').bind("restoreBackground", (function(_this) {
      return function(e) {
        return _this.restore();
      };
    })(this));
    return $('body').bind("setBackground", (function(_this) {
      return function(e, project) {
        return _this.setProject(project);
      };
    })(this));
  };

  Background.prototype.relayout = function() {
    var resize;
    resize = function(that, flexibleSize) {
      var aspectRatio, windowRatio;
      if (flexibleSize === "full") {
        flexibleSize = "100%";
      }
      aspectRatio = that.height() / that.width();
      windowRatio = $(window).height() / $(window).width();
      if (windowRatio > aspectRatio) {
        that.height($(window).height());
        return that.width(flexibleSize);
      } else {
        that.height(flexibleSize);
        return that.width($(window).width());
      }
    };
    resize(this.uis.image, "full");
    return resize(this.uis.mask, "full");
  };

  Background.prototype.setProject = function(project_obj) {
    this.resetClass();
    setTimeout(((function(_this) {
      return function() {
        return _this.ui.addClass(project_obj.key);
      };
    })(this)), 0.20);
    if (project_obj.backgroundVideos) {
      if (Modernizr.video) {
        return $('body').trigger("setVideos", "" + project_obj.backgroundVideos);
      } else {
        return $('body').trigger("setImage", project_obj.backgroundImage);
      }
    } else if (project_obj.backgroundImage) {
      return $('body').trigger("setImage", project_obj.backgroundImage);
    } else {
      return $('body').trigger("setNoVideo");
    }
  };

  Background.prototype.suspend = function() {
    this.CACHE.suspended = true;
    this.uis.image.addClass("pasla");
    return this.ui.find('video.actual').addClass("hidden");
  };

  Background.prototype.restore = function() {
    this.ui.find('video.actual').removeClass("hidden");
    this.uis.image.removeClass("pasla");
    return this.CACHE.suspended = false;
  };

  Background.prototype.removeVideo = function() {
    return this.ui.find('video.actual').remove();
  };

  Background.prototype.video = function(data) {
    var extension, file, nui, old_nui, source, type, _i, _len;
    old_nui = this.ui.find('video.actual');
    nui = this.uis.video.cloneTemplate().addClass("hidden");
    this.uis.image.addClass("pasla");
    nui.prop('muted', true);
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      file = data[_i];
      extension = file.split('.').pop();
      source = $('<source />').attr("src", this.CONFIG.videoUrl + file);
      type = extension;
      if (extension === "ogv") {
        type = "ogg";
      }
      source.attr("type", "video/" + type);
      nui.append(source);
    }
    if (this.CACHE.image !== null) {
      nui.attr("poster", this.CONFIG.imageUrl + this.CACHE.image);
    }
    nui.on("canplay canplaythrough", (function(_this) {
      return function() {
        if (!_this.CACHE.suspended) {
          old_nui.remove();
          return nui.removeClass("hidden");
        }
      };
    })(this));
    return this.uis.video.after(nui);
  };

  Background.prototype.image = function(filename, is_default) {
    var nui, old_nui;
    if (is_default == null) {
      is_default = false;
    }
    old_nui = this.ui.find('.image.actual');
    old_nui.addClass("pasla");
    if (is_default) {
      $("<img/>").attr('src', "" + this.CONFIG.imageUrl + filename).load((function(_this) {
        return function() {
          _this.uis.image.css("background-image", "url(" + _this.CONFIG.imageUrl + filename + ")");
          _this.uis.image.removeClass("pasla");
          return setTimeout((function() {
            return old_nui.remove();
          }), 1000);
        };
      })(this));
      return;
    }
    this.uis.image.addClass("pasla");
    nui = this.uis.image.cloneTemplate().addClass("pasla").css("background-image", "");
    this.uis.video.before(nui);
    this.relayout(this.uis.image);
    this.CACHE.image = filename;
    return $("<img/>").attr('src', "" + this.CONFIG.imageUrl + filename).load((function(_this) {
      return function() {
        nui.css("background-image", "url(" + _this.CONFIG.imageUrl + filename + ")");
        nui.removeClass("pasla");
        return setTimeout((function() {
          return old_nui.remove();
        }), 1000);
      };
    })(this));
  };

  Background.prototype.darkness = function(darklevel) {
    return this.uis.darkness.css("opacity", darklevel);
  };

  Background.prototype.resetClass = function() {
    this.ui.removeClass();
    return this.ui.addClass("Background widget");
  };

  return Background;

})(Widget);

portfolio.Panel = (function(_super) {
  __extends(Panel, _super);

  function Panel() {
    this.isOpened = __bind(this.isOpened, this);
    this.cancelDelayedPanel = __bind(this.cancelDelayedPanel, this);
    this.open = __bind(this.open, this);
    this.hide = __bind(this.hide, this);
    this.relayout = __bind(this.relayout, this);
    this.goto = __bind(this.goto, this);
    this.bindUI = __bind(this.bindUI, this);
    this.OPTIONS = {
      panelHeightClosed: 40,
      delay: 0
    };
    this.PAGES = ["project", "contact", "news"];
    this.UIS = {
      wrapper: ".wrapper:first",
      pages: ".pages",
      close: ".close",
      contents: ".content"
    };
    this.cache = {
      isOpened: false,
      currentTab: null,
      currentPage: null,
      footerBarHeight: 0,
      tilesHeight: null
    };
  }

  Panel.prototype.bindUI = function(ui) {
    Panel.__super__.bindUI.apply(this, arguments);
    this.background = Widget.ensureWidget(".Background");
    this.cancelDelay = false;
    $('body').bind('setPanelPage', (function(_this) {
      return function(e, page) {
        return _this.goto(page);
      };
    })(this));
    $('body').bind('setDirectPanelPage', (function(_this) {
      return function(e, page) {
        return _this.goto(page, false);
      };
    })(this));
    $('body').bind('hidePanel', this.hide);
    $('body').bind('cancelDelayedPanel', this.cancelDelayedPanel);
    $(window).resize((function(_this) {
      return function() {
        return _this.relayout(_this.cache.isOpened);
      };
    })(this));
    this.uis.close.click((function(_this) {
      return function(e) {
        e.preventDefault();
        Widget.ensureWidget(".Navigation").updatePanelMenu();
        return _this.hide();
      };
    })(this));
    return this;
  };

  Panel.prototype.goto = function(page, delay) {
    if (delay == null) {
      delay = true;
    }
    this.uis.wrapper.find('.page').removeClass("show");
    this.uis.wrapper.find('.' + Format.StringFormat.Capitalize(page)).addClass("show");
    this.uis.wrapper.find('.' + Format.StringFormat.Capitalize(page) + ' .content').addClass("active");
    if (delay) {
      this.open(page);
    } else {
      this.open();
    }
    return this.cache.currentPage = page;
  };

  Panel.prototype.relayout = function(open) {
    var height, offset_left, window_height;
    this.cache.isOpened = open;
    if (this.cache.isOpened) {
      window_height = $(window).height();
      height = $(window).height() - 218;
      if (height > 0) {
        this.ui.css({
          height: height
        });
      }
      this.ui.css({
        bottom: $(".FooterBar").height()
      });
    } else {
      this.ui.css({
        bottom: 0 - this.ui.height()
      });
    }
    offset_left = parseInt($(".FooterBar .wrapper:first").offset().left) + 60;
    $(".Page.links").css({
      left: offset_left
    });
    return setTimeout(((function(_this) {
      return function() {
        return $('body').trigger("relayoutContent");
      };
    })(this)), 100);
  };

  Panel.prototype.hide = function() {
    this.cache.isOpened = false;
    this.relayout(false);
    setTimeout(((function(_this) {
      return function() {
        return _this.uis.wrapper.addClass("hidden");
      };
    })(this)), 100);
    this.background.darkness(0);
    return $('body').trigger("updatePanelMenuRoot", false);
  };

  Panel.prototype.open = function(page) {
    var delay;
    if (page === "project") {
      delay = this.OPTIONS.delay;
    } else {
      delay = 0;
    }
    setTimeout((function(_this) {
      return function() {
        if (!_this.cancelDelay) {
          _this.cache.isOpened = true;
          _this.ui.removeClass("hidden");
          _this.uis.wrapper.removeClass("hidden");
          _this.relayout(true);
          _this.background.darkness(0.6);
          return $('body').trigger("updatePanelMenuRoot", true);
        }
      };
    })(this), delay);
    return this.cancelDelay = false;
  };

  Panel.prototype.cancelDelayedPanel = function() {
    return this.cancelDelay = true;
  };

  Panel.prototype.isOpened = function() {
    return this.cache.isOpened;
  };

  return Panel;

})(Widget);

portfolio.FlickrGallery = (function(_super) {
  __extends(FlickrGallery, _super);

  function FlickrGallery() {
    this.setData = __bind(this.setData, this);
    this._makePhotoTile = __bind(this._makePhotoTile, this);
    this.getPhotoSet = __bind(this.getPhotoSet, this);
    this.setPhotoSet = __bind(this.setPhotoSet, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      list: ".photos",
      photoTmpl: "li.photo.template"
    };
    this.cache = {
      data: null
    };
    this.imagePlayer = null;
  }

  FlickrGallery.prototype.bindUI = function(ui) {
    FlickrGallery.__super__.bindUI.apply(this, arguments);
    this.imagePlayer = Widget.ensureWidget(".ImagePlayer");
    return this;
  };

  FlickrGallery.prototype.setPhotoSet = function(set_id) {
    return $.ajax("/api/flickr/photosSet/" + set_id + "/qualities/q,z", {
      dataType: 'json',
      success: this.setData
    });
  };

  FlickrGallery.prototype.getPhotoSet = function() {
    return this.cache.data;
  };

  FlickrGallery.prototype._makePhotoTile = function(photoData, index) {
    var nui;
    nui = this.uis.photoTmpl.cloneTemplate();
    nui.find(".image").css("background-image", "url(" + photoData.q + ")");
    nui.find("a").attr("href", "#+item=" + index);
    return this.uis.list.append(nui);
  };

  FlickrGallery.prototype.setData = function(data) {
    var index, params, photo, _i, _len;
    this.uis.list.find('li:not(.template)').remove();
    this.cache.data = data;
    for (index = _i = 0, _len = data.length; _i < _len; index = ++_i) {
      photo = data[index];
      this._makePhotoTile(photo, index);
    }
    URL.enableLinks(this.uis.list);
    params = URL.get();
    if (params.item && URL.get("cat") === "gallery") {
      this.imagePlayer.setData(this.getPhotoSet());
    }
    return URL.onStateChanged((function(_this) {
      return function() {
        if (URL.get("item")) {
          if ((URL.get("cat") != null) && URL.get("cat") === "gallery") {
            return _this.imagePlayer.setData(_this.getPhotoSet());
          }
        }
      };
    })(this));
  };

  return FlickrGallery;

})(Widget);

portfolio.News = (function(_super) {
  __extends(News, _super);

  function News() {
    this.setData = __bind(this.setData, this);
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      newsTmpl: ".template",
      newsContainer: "ul",
      content: ".content"
    };
    this.cache = {
      data: null
    };
  }

  News.prototype.bindUI = function(ui) {
    News.__super__.bindUI.apply(this, arguments);
    $.ajax("/api/news/all", {
      dataType: 'json',
      success: this.setData
    });
    $("body").bind("relayoutContent", this.relayout);
    return this;
  };

  News.prototype.relayout = function() {
    var top_offset;
    top_offset = $('.FooterPanel').height() - 80;
    return this.ui.find(".content").css({
      height: top_offset
    }).jScrollPane({
      hideFocus: true
    });
  };

  News.prototype.setData = function(data) {
    var date, news, nui, _i, _len, _results;
    this.cache.data = data;
    _results = [];
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      news = data[_i];
      date = new Date(news.date_creation);
      nui = this.uis.newsTmpl.cloneTemplate({
        body: news.content.replace(/\n/g, "<br />"),
        date: date.toDateString()
      });
      nui.find(".title").append(news.title);
      _results.push(this.uis.newsContainer.append(nui));
    }
    return _results;
  };

  return News;

})(Widget);

portfolio.Contact = (function(_super) {
  __extends(Contact, _super);

  function Contact() {
    this.sendMessage = __bind(this.sendMessage, this);
    this.showForm = __bind(this.showForm, this);
    this.showMain = __bind(this.showMain, this);
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      main: ".main",
      form: ".contactForm",
      email: ".email",
      message: ".message",
      results: ".result",
      errorMsg: ".result.error",
      successMsg: ".result.success",
      content: ".content"
    };
    this.CONFIG = {
      minMessageHeight: 200
    };
    this.ACTIONS = ["showForm", "showMain", "sendMessage"];
  }

  Contact.prototype.bindUI = function(ui) {
    Contact.__super__.bindUI.apply(this, arguments);
    $('body').bind('currentPage', (function(_this) {
      return function(e, page) {
        if (page === "contact") {
          return _this.showMain();
        }
      };
    })(this));
    $('body').bind('relayoutContent', this.relayout);
    return this;
  };

  Contact.prototype.relayout = function() {
    var messageHeight, top_offset;
    top_offset = $(".FooterPanel").height() - 80;
    messageHeight = $(window).height() - this.uis.message.offset().top - 190;
    if (messageHeight < this.CONFIG.minMessageHeight) {
      messageHeight = this.CONFIG.minMessageHeight;
    }
    this.uis.message.css({
      height: messageHeight
    });
    return this.uis.content.css({
      height: top_offset
    }).jScrollPane({
      hideFocus: true
    });
  };

  Contact.prototype.showMain = function() {
    this.uis.form.addClass("hidden");
    this.uis.main.removeClass("hidden");
    return this.relayout();
  };

  Contact.prototype.showForm = function() {
    this.uis.form.removeClass("hidden");
    this.uis.main.addClass("hidden");
    this.uis.results.addClass("hidden");
    return this.relayout();
  };

  Contact.prototype.sendMessage = function() {
    var email, message;
    this.uis.results.addClass("hidden");
    email = this.uis.form.find('[name=email]').val();
    message = this.uis.form.find('[name=message]').val();
    return $.ajax("/api/contact", {
      type: "POST",
      dataType: 'json',
      data: {
        email: email,
        message: message
      },
      success: ((function(_this) {
        return function(msg) {
          return _this.uis.successMsg.removeClass("hidden");
        };
      })(this)),
      error: ((function(_this) {
        return function(msg) {
          return _this.uis.errorMsg.removeClass("hidden");
        };
      })(this))
    });
  };

  return Contact;

})(Widget);

portfolio.Project = (function(_super) {
  __extends(Project, _super);

  function Project() {
    this.selectTab = __bind(this.selectTab, this);
    this.setContent = __bind(this.setContent, this);
    this.setMenu = __bind(this.setMenu, this);
    this.setProject = __bind(this.setProject, this);
    this.getProjectByName = __bind(this.getProjectByName, this);
    this.setData = __bind(this.setData, this);
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      tabs: ".tabs",
      tabContent: ".content",
      tabContents: ".contents",
      tabList: ".tabs li"
    };
    this.cache = {
      footerBarHeight: 0,
      data: null,
      externalVideo: false
    };
    this.CATEGORIES = ["synopsis", "videos", "gallery", "screenings", "credits", "press", "links", "distribution", "facebook"];
    this.flickrGallery = null;
    this.videoPlayer = null;
    this.downloader = null;
  }

  Project.prototype.bindUI = function(ui) {
    Project.__super__.bindUI.apply(this, arguments);
    this.flickrGallery = Widget.ensureWidget(".content.gallery");
    this.videoPlayer = Widget.ensureWidget(".VideoPlayer");
    $.ajax("/api/data", {
      dataType: 'json',
      success: this.setData
    });
    URL.enableLinks(this.ui);
    $("body").bind("relayoutContent", this.relayout);
    this.downloader = Widget.ensureWidget(".Download");
    return this.ui.find(".presskit a").click(((function(_this) {
      return function() {
        return _this.downloader.show();
      };
    })(this)));
  };

  Project.prototype.relayout = function() {
    var top_offset;
    top_offset = $('.FooterPanel').height() - 100;
    return this.ui.find(".content").css({
      height: top_offset
    }).jScrollPane({
      hideFocus: true
    });
  };

  Project.prototype.setData = function(data) {
    var params;
    this.cache.data = data;
    params = URL.get();
    if (params.project) {
      this.setProject(params.project);
      this.selectTab(URL.get("cat") || "synopsis");
    }
    if (params.item) {
      if ((URL.get("cat") != null) && URL.get("cat") === "videos") {
        this.videoPlayer.setData(this.getProjectByName(URL.get("project")).videos);
      }
    }
    return URL.onStateChanged((function(_this) {
      return function() {
        if (URL.hasChanged("project")) {
          if (URL.get("project") != null) {
            _this.setProject(URL.get("project"));
            _this.selectTab(URL.get("cat") || "synopsis");
          }
        }
        if (URL.hasChanged("cat")) {
          if (URL.get("cat") != null) {
            _this.selectTab(URL.get("cat"));
          }
        }
        if (URL.get("item") != null) {
          if ((URL.get("cat") != null) && URL.get("cat") === "videos") {
            return _this.videoPlayer.setData(_this.getProjectByName(URL.get("project")).videos);
          }
        }
      };
    })(this));
  };

  Project.prototype.getProjectByName = function(name) {
    var project, _i, _len, _ref;
    _ref = this.cache.data.works;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      project = _ref[_i];
      if (project.key === name) {
        return project;
      }
    }
  };

  Project.prototype.setProject = function(project) {
    var project_obj;
    project_obj = this.getProjectByName(project);
    this.setMenu(project_obj);
    this.setContent(project_obj);
    return $('body').trigger("setBackground", project_obj);

    /*		if project_obj.backgroundVideos
    			$('body').trigger("setImage", project_obj.backgroundImage)				
    			$('body').trigger("setVideos", ""+project_obj.backgroundVideos)
    		else if project_obj.backgroundImage
    			$('body').trigger("setImage", project_obj.backgroundImage)				
    		else
    			$('body').trigger("setNoVideo")
     */
  };

  Project.prototype.setMenu = function(project) {
    var category, _i, _len, _ref;
    this.uis.tabList.addClass("hidden");
    _ref = this.CATEGORIES;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      category = _ref[_i];
      if (project[category] != null) {
        if (project.key === "nana" && category === "videos") {
          this.uis.tabs.find("." + category + "Nana").removeClass("hidden");
        } else {
          this.uis.tabs.find("." + category).removeClass("hidden");
        }
      }
    }
    if (project.facebook != null) {
      this.ui.find("[data-name=facebook]").attr('href', project.facebook);
    }
    if (project.videos != null) {
      if (project.videos.length === 0) {
        this.cache.externalVideo = true;
        this.ui.find("[data-name=videos]").bind("click.external", (function(_this) {
          return function(e) {
            e.preventDefault();
            return window.open('http://www.nfb.ca/film/baghdad_twist', '_blank');
          };
        })(this));
      } else {
        this.cache.externalVideo = false;
        this.ui.find("[data-name=videos]").unbind("click.external");
      }
    }
    return URL.enableLinks(this.uis.tabs);
  };

  Project.prototype.setContent = function(project) {
    var body_nui, category, credit, credit_nui, i, link, link_nui, list, nui, press, press_nui, presskit, readmoreLink, screening, screening_nui, synopsis_nui, teaser, value, video, video_nui, _i, _j, _len, _len1, _ref, _results;
    _results = [];
    for (category in project) {
      value = project[category];
      if (__indexOf.call(this.CATEGORIES, category) >= 0) {
        nui = this.uis.tabContents.find("[data-name=" + category + "] .wrapper");
        switch (category) {
          case "synopsis":
            nui.find(".actual").remove();
            synopsis_nui = nui.find('.template').cloneTemplate(value);
            nui.append(synopsis_nui);
            readmoreLink = nui.find('.readmore');
            body_nui = nui.find('.actual .body');
            body_nui.html(body_nui.html().replace(/\n/g, "<br />"));
            teaser = nui.find(".actual .teaser");
            if (value.teaser != null) {
              teaser.removeClass("hidden");
              body_nui.css({
                display: 'none'
              });
              teaser.html(teaser.html().replace(/\n/g, "<br />"));
              readmoreLink.removeClass("hidden");
              body_nui.removeClass("readmoreFx");
              $('body').bind('readmore.init', (function(_this) {
                return function() {
                  body_nui.css({
                    "display": "none"
                  });
                  return readmoreLink.removeClass("hidden");
                };
              })(this));
              _results.push(readmoreLink.click((function(_this) {
                return function(e) {
                  e.preventDefault();
                  body_nui.removeClass("hidden");
                  body_nui.css({
                    display: 'block'
                  });
                  readmoreLink.addClass("hidden");
                  return setTimeout((function() {
                    body_nui.addClass("readmoreFx");
                    return _this.relayout();
                  }), 200);
                };
              })(this)));
            } else {
              teaser.addClass('hidden');
              readmoreLink.addClass("hidden");
              _results.push(body_nui.css({
                display: 'block',
                opacity: 1
              }));
            }
            break;
          case "videos":
            list = nui.find("ul");
            list.find("li:not(.template)").remove();
            for (i = _i = 0, _len = value.length; _i < _len; i = ++_i) {
              video = value[i];
              video_nui = nui.find(".template").cloneTemplate({
                duration: Format.NumberFormat.SecondToString(video.duration),
                title: video.title
              });
              video_nui.find('img').attr("src", video.thumbnail_large);
              video_nui.find('a').attr("href", "#+item=" + i);
              list.append(video_nui);
            }
            _results.push(URL.enableLinks(list));
            break;
          case "gallery":
            _results.push(this.flickrGallery.setPhotoSet(project.gallery));
            break;
          case "press":
            nui.find(".actual").remove();
            if (value.press != null) {
              _ref = value.press;
              for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                press = _ref[_j];
                press_nui = nui.find('.template').cloneTemplate(press);
                nui.append(press_nui);
              }
            }
            presskit = nui.find(".presskit");
            if (value.presskit != null) {
              presskit.removeClass("hidden");
              _results.push(presskit.find("a").attr("href", value.presskit.link));
            } else {
              _results.push(presskit.addClass("hidden"));
            }
            break;
          case "credits":
            nui.find(".actual").remove();
            _results.push((function() {
              var _k, _len2, _results1;
              _results1 = [];
              for (_k = 0, _len2 = value.length; _k < _len2; _k++) {
                credit = value[_k];
                credit_nui = nui.find('.template').cloneTemplate(credit, true);
                _results1.push(nui.append(credit_nui));
              }
              return _results1;
            })());
            break;
          case "screenings":
            nui.find(".actual").remove();
            _results.push((function() {
              var _k, _len2, _results1;
              _results1 = [];
              for (_k = 0, _len2 = value.length; _k < _len2; _k++) {
                screening = value[_k];
                screening_nui = nui.find('.template').cloneTemplate(screening, true);
                _results1.push(nui.append(screening_nui));
              }
              return _results1;
            })());
            break;
          case "links":
            nui.find(".actual").remove();
            _results.push((function() {
              var _k, _len2, _results1;
              _results1 = [];
              for (_k = 0, _len2 = value.length; _k < _len2; _k++) {
                link = value[_k];
                link_nui = nui.find(".template").cloneTemplate(link);
                link_nui.find('a').html(link.description).attr("href", link.link);
                _results1.push(nui.append(link_nui));
              }
              return _results1;
            })());
            break;
          case "distribution":
            nui.empty();
            _results.push(nui.append(value.replace(/\n/g, "<br />")));
            break;
          default:
            _results.push(void 0);
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  Project.prototype.selectTab = function(category) {
    var tab_nui;
    if (!(this.cache.externalVideo && category === "videos")) {
      this.uis.tabContent.removeClass("active");
      this.uis.tabContent.removeClass("show");
      this.uis.tabContent.addClass("hidden");
      this.uis.tabList.find("a").removeClass("active");
      this.uis.tabList.find("[data-name=" + category + "]").addClass("active");
      tab_nui = this.uis.tabContents.find("[data-name=" + category + "]");
      tab_nui.removeClass("hidden");
      setTimeout(((function(_this) {
        return function() {
          return tab_nui.addClass("active");
        };
      })(this)), 100);
      $('body').trigger("readmore.init");
      return this.relayout();
    }
  };

  return Project;

})(Widget);

portfolio.MediaPlayer = (function(_super) {
  __extends(MediaPlayer, _super);

  function MediaPlayer() {
    this.hide = __bind(this.hide, this);
    this.show = __bind(this.show, this);
    this.previous = __bind(this.previous, this);
    this.next = __bind(this.next, this);
    this.setThumbnail = __bind(this.setThumbnail, this);
    this.setPage = __bind(this.setPage, this);
    this.toggleNavigation = __bind(this.toggleNavigation, this);
    this.setData = __bind(this.setData, this);
    this.setMedia = __bind(this.setMedia, this);
    this.onURLStateChanged = __bind(this.onURLStateChanged, this);
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.OPTIONS = {
      nbTiles: 5
    };
    this.cache = {
      data: null,
      currentPage: null,
      isShown: false,
      currentItem: null,
      isTrailer: null
    };
    this.ACTIONS = ["hide", "next", "previous"];
  }

  MediaPlayer.prototype.bindUI = function(ui) {
    MediaPlayer.__super__.bindUI.apply(this, arguments);
    URL.onStateChanged(this.onURLStateChanged);
    return $(window).resize(this.relayout);
  };

  MediaPlayer.prototype.relayout = function() {
    var img, player_height, player_width, player_width_max, ratio;
    if ((this.cache.data != null) && this.cache.isShown) {
      ratio = this.cache.data[this.cache.currentItem].ratio;
      if (ratio == null) {
        img = $("<img>").attr("src", this.cache.data[this.cache.currentItem].media);
        img.load((function(_this) {
          return function(e) {
            ratio = _this.cache.data[_this.cache.currentItem].ratio = e.currentTarget.width / e.currentTarget.height;
            return _this.relayout();
          };
        })(this));
      } else {
        player_width_max = $(window).width() - 100;
        player_height = this.uis.panel.offset().top - 50;
        player_width = player_height * ratio;
        if (player_width > player_width_max) {
          player_width = player_width_max;
          player_height = player_width / ratio;
        }
        this.uis.player.attr({
          height: player_height,
          width: player_width
        });
        this.uis.playerContainer.css("width", player_width);
      }
      return this.uis.waiter.css({
        top: $(window).height() / 2
      });
    }
  };

  MediaPlayer.prototype.onURLStateChanged = function() {
    if (this.cache.isShown) {
      if (URL.hasChanged("item")) {
        if (URL.get("item")) {
          return this.setMedia(URL.get("item"));
        } else {
          return this.hide();
        }
      }
    }
  };

  MediaPlayer.prototype.setMedia = function(index) {
    this.cache.currentItem = parseInt(index);
    URL.update({
      item: index
    }, true);
    this.relayout();
    if (URL.get("trailer") === "true") {
      return this.uis.panel.opacity(0).css({
        "z-index": 0
      });
    } else {
      return this.uis.panel.opacity(1).css({
        "z-index": 11
      });
    }
  };

  MediaPlayer.prototype.setData = function(data) {
    var page, params;
    params = URL.get();
    if (params.item != null) {
      this.show();
      page = Math.ceil((params.item / this.OPTIONS.nbTiles) + 0.1) - 1;
      this.setPage(page);
      return this.setMedia(params.item);
    }
  };

  MediaPlayer.prototype.toggleNavigation = function() {
    var page;
    page = this.cache.currentPage;
    this.uis.previous.opacity(1);
    this.uis.next.opacity(1);
    if (page === 0) {
      this.uis.previous.opacity(0);
    }
    if (page >= Math.ceil((this.cache.data.length / this.OPTIONS.nbTiles) + 0.1) - 1) {
      return this.uis.next.opacity(0);
    }
  };

  MediaPlayer.prototype.setPage = function(page, callback) {
    var reverse, start, thumbnail_to_preload, tiles, _;
    if (callback == null) {
      callback = null;
    }
    page = parseInt(page);
    if (page > this.cache.data.length / this.OPTIONS.nbTiles || page < 0) {
      return false;
    }
    if ((this.cache.currentPage == null) || (page !== this.cache.currentPage)) {
      start = this.OPTIONS.nbTiles * page;
      tiles = this.uis.mediaContainer.find("li.actual");
      reverse = this.cache.currentPage > page;
      this.cache.currentPage = page;
      thumbnail_to_preload = (function() {
        var _i, _len, _ref, _results;
        _ref = this.cache.data.slice(start, +(this.OPTIONS.nbTiles - 1) + 1 || 9e9);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ = _ref[_i];
          _results.push(_.thumbnail);
        }
        return _results;
      }).call(this);
      return $.preload(thumbnail_to_preload, (function(_this) {
        return function() {
          var i, interval;
          tiles = _this.uis.mediaList.find("li.actual");
          i = 0;
          return interval = setInterval((function() {
            var index, item, nui, virtual_i;
            virtual_i = reverse ? _this.OPTIONS.nbTiles - 1 - i : i;
            index = start + virtual_i;
            item = _this.cache.data[index];
            nui = $(tiles[virtual_i]);
            if (item != null) {
              if ((nui == null) || nui.length < 1) {
                nui = _this.uis.mediaTmpl.cloneTemplate();
                _this.uis.mediaList.append(nui);
              }
              nui.removeClass("show hide");
              nui.find("a").attr("href", "#+item=" + index);
              setTimeout((function() {
                return _this.setThumbnail(virtual_i, nui, item.thumbnail);
              }), 250);
            } else {
              if (nui != null) {
                nui.addClass("hide");
              }
            }
            i += 1;
            if (i >= _this.OPTIONS.nbTiles) {
              URL.enableLinks(_this.uis.mediaList);
              if (callback != null) {
                callback();
              }
              setTimeout((function() {
                return _this.toggleNavigation();
              }), 250);
              return clearInterval(interval);
            }
          }), 200);
        };
      })(this));
    }
  };

  MediaPlayer.prototype.setThumbnail = function(index_in_page, nui, thumbnail_url) {
    var image;
    image = nui.find(".image");
    if (this.setCurrentTileForVideo != null) {
      this.setCurrentTileForVideo(index_in_page, nui);
    }
    if (image.prop("tagName") === "DIV") {
      image.css("background-image", "url(" + thumbnail_url + ")");
    } else if (image.prop("tagName") === "IMG") {
      image.attr("src", thumbnail_url);
    }
    return nui.addClass("show");
  };

  MediaPlayer.prototype.next = function() {
    return this.setPage(this.cache.currentPage + 1);
  };

  MediaPlayer.prototype.previous = function() {
    var new_page;
    new_page = this.cache.currentPage - 1;
    if (new_page < 0) {
      return this.setPage(0);
    } else {
      return this.setPage(new_page);
    }
  };

  MediaPlayer.prototype.show = function() {
    MediaPlayer.__super__.show.apply(this, arguments);
    this.uis.playerContainer.removeClass("hidden");
    this.cache.isShown = true;
    $(".FooterPanel").addClass("hidden");
    $(".Page.links .back").removeClass("hidden").click((function(_this) {
      return function(e) {
        _this.hide();
        return e.preventDefault();
      };
    })(this)).find("a").html($(".PageMenu .tile .wrapper").html());
    $("body").trigger("hidePanel");
    $('body').trigger("darkness", 0.7);
    this.uis.next.removeClass("hidden");
    this.uis.previous.removeClass("hidden");
    $('body').trigger("suspendBackground");
    return $('body').trigger("desactivatelPanelToggler");
  };

  MediaPlayer.prototype.hide = function() {
    MediaPlayer.__super__.hide.apply(this, arguments);
    $(".Page.links .back").addClass("hidden");
    $('body').trigger("restoreBackground");
    this.ui.find(".player").addClass("hidden");
    this.uis.playerContainer.addClass("hidden");
    URL.remove("item", true);
    this.cache.isShown = false;
    this.cache.currentPage = null;
    this.cache.currentItem = null;
    $(".Panel").show();
    $('body').trigger("darkness", 0.3);
    $("body").trigger("setDirectPanelPage", URL.get("page"));
    this.uis.mediaList.find("li.actual").remove();
    this.uis.next.addClass("hidden");
    this.uis.previous.addClass("hidden");
    $('body').trigger("activatelPanelToggler");
    if (URL.get("trailer") === "true") {
      return URL.update({
        trailer: null,
        cat: "synopsis"
      });
    }
  };

  return MediaPlayer;

})(Widget);

portfolio.VideoPlayer = (function(_super) {
  __extends(VideoPlayer, _super);

  function VideoPlayer() {
    this.hide = __bind(this.hide, this);
    this.setCurrentTileForVideo = __bind(this.setCurrentTileForVideo, this);
    this.setMedia = __bind(this.setMedia, this);
    this.setData = __bind(this.setData, this);
    VideoPlayer.__super__.constructor.apply(this, arguments);
    this.UIS = {
      playerContainer: ".videoPlayer",
      player: ".videoPlayer iframe",
      panel: ".mediaPanel",
      mediaContainer: ".mediaPanel .mediaContainer",
      mediaList: ".mediaPanel .mediaContainer ul",
      mediaTmpl: ".mediaPanel .media.template",
      close: ".close",
      next: ".next",
      previous: ".previous",
      waiter: ".waiter"
    };
  }

  VideoPlayer.prototype.setData = function(data) {
    var d, new_data;
    new_data = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        d = data[_i];
        _results.push({
          thumbnail: d.thumbnail_small,
          media: d.id,
          ratio: d.width / d.height,
          duration: d.duration,
          title: d.title
        });
      }
      return _results;
    })();
    this.cache.data = new_data;
    return VideoPlayer.__super__.setData.call(this);
  };

  VideoPlayer.prototype.setMedia = function(index) {
    var animation, index_in_page, info, li, page;
    VideoPlayer.__super__.setMedia.apply(this, arguments);
    this.uis.player.addClass("hidden").attr("src", "").attr("src", "http://player.vimeo.com/video/" + this.cache.data[index].media + "?portrait=0&title=0&byline=0&autoplay=1");
    animation = setTimeout(((function(_this) {
      return function() {
        return _this.uis.waiter.removeClass("hidden");
      };
    })(this)), 750);
    this.uis.player.load((function(_this) {
      return function() {
        clearTimeout(animation);
        _this.uis.player.removeClass("hidden");
        return _this.uis.waiter.addClass("hidden");
      };
    })(this));
    index = this.cache.currentItem;
    page = Math.ceil((index / this.OPTIONS.nbTiles) + 0.1) - 1;
    if (page === this.cache.currentPage) {
      index_in_page = index % this.OPTIONS.nbTiles;
      li = $(this.uis.mediaList.find("li.actual").removeClass("current")[index_in_page]);
      li.addClass("current");
      info = Format.NumberFormat.SecondToString(this.cache.data[index].duration) + "<br/>" + this.cache.data[index].title;
      return li.find(".overlay").html(info);
    }
  };

  VideoPlayer.prototype.setCurrentTileForVideo = function(index, nui) {
    var index_in_page, info, page_current_item;
    nui.removeClass("current");
    page_current_item = Math.ceil((this.cache.currentItem / this.OPTIONS.nbTiles) + 0.1) - 1;
    if (this.cache.currentPage === page_current_item) {
      index_in_page = this.cache.currentItem % this.OPTIONS.nbTiles;
      if (index_in_page === index) {
        nui.addClass("current");
        info = Format.NumberFormat.SecondToString(this.cache.data[this.cache.currentItem].duration) + "<br/>" + this.cache.data[this.cache.currentItem].title;
        return nui.find(".overlay").html(info);
      }
    }
  };

  VideoPlayer.prototype.hide = function() {
    VideoPlayer.__super__.hide.apply(this, arguments);
    return this.uis.player.attr("src", "");
  };

  return VideoPlayer;

})(portfolio.MediaPlayer);

portfolio.ImagePlayer = (function(_super) {
  __extends(ImagePlayer, _super);

  function ImagePlayer() {
    this.hide = __bind(this.hide, this);
    this.setMedia = __bind(this.setMedia, this);
    this.setData = __bind(this.setData, this);
    this.bindUI = __bind(this.bindUI, this);
    ImagePlayer.__super__.constructor.apply(this, arguments);
    this.UIS = {
      playerContainer: ".imagePlayer",
      player: ".imagePlayer .wrapper > img",
      panel: ".mediaPanel",
      mediaContainer: ".mediaPanel .mediaContainer",
      mediaList: ".mediaPanel .mediaContainer ul",
      mediaTmpl: ".mediaPanel .media.template",
      close: ".close",
      next: ".next",
      previous: ".previous",
      waiter: ".waiter"
    };
  }

  ImagePlayer.prototype.bindUI = function(ui) {
    ImagePlayer.__super__.bindUI.apply(this, arguments);
    return this.uis.playerContainer.click((function(_this) {
      return function(e) {
        var new_item;
        new_item = _this.cache.currentItem + 1;
        if (new_item < _this.cache.data.length) {
          _this.setMedia(new_item);
        } else {
          _this.hide();
        }
        e.preventDefault();
        return false;
      };
    })(this));
  };

  ImagePlayer.prototype.setData = function(data) {
    var d, new_data;
    new_data = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        d = data[_i];
        _results.push({
          thumbnail: d.q,
          media: d.z
        });
      }
      return _results;
    })();
    this.cache.data = new_data;
    return ImagePlayer.__super__.setData.call(this);
  };

  ImagePlayer.prototype.setMedia = function(index) {
    var animation, img;
    ImagePlayer.__super__.setMedia.apply(this, arguments);
    img = $("<img/>").attr("src", this.cache.data[index].media);
    this.uis.player.addClass("hidden");
    animation = setTimeout(((function(_this) {
      return function() {
        return _this.uis.waiter.removeClass("hidden");
      };
    })(this)), 750);
    return img.load((function(_this) {
      return function() {
        clearTimeout(animation);
        _this.uis.waiter.addClass("hidden");
        return _this.uis.player.attr("src", _this.cache.data[index].media).removeClass("hidden");
      };
    })(this));
  };

  ImagePlayer.prototype.hide = function() {
    ImagePlayer.__super__.hide.apply(this, arguments);
    return this.uis.player.css("background-image", "");
  };

  return ImagePlayer;

})(portfolio.MediaPlayer);

portfolio.Language = (function(_super) {
  __extends(Language, _super);

  function Language() {
    this.toggle = __bind(this.toggle, this);
    this.actualize = __bind(this.actualize, this);
    this.onURLStateChanged = __bind(this.onURLStateChanged, this);
    this.setData = __bind(this.setData, this);
    this.getLanguage = __bind(this.getLanguage, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      languageTmpl: ".language.template"
    };
    this.OPTIONS = {
      languages: ['en', 'fr', 'it']
    };
    this.cache = {
      language: null
    };
  }

  Language.prototype.bindUI = function(ui) {
    Language.__super__.bindUI.apply(this, arguments);
    URL.enableLinks(this.ui);
    URL.onStateChanged(this.onURLStateChanged);
    if (URL.get("ln")) {
      this.cache.language = URL.get("ln");
      return this.toggle();
    } else {
      return this.getLanguage();
    }
  };

  Language.prototype.getLanguage = function() {
    return $.ajax("/api/getLanguage", {
      success: this.setData
    });
  };

  Language.prototype.setData = function(data) {
    this.cache.language = data;
    return this.toggle();
  };

  Language.prototype.onURLStateChanged = function() {
    if (URL.hasChanged("ln") && URL.get("ln")) {
      return $.ajax("/api/setLanguage/" + URL.get("ln"), {
        dataType: 'json',
        success: this.actualize
      });
    } else {
      return this.toggle();
    }
  };

  Language.prototype.actualize = function() {
    return document.location.reload(true);
  };

  Language.prototype.toggle = function() {
    var nui, other_language, other_languages, _i, _len;
    if (this.cache.language != null) {
      other_languages = Utils.clone(this.OPTIONS.languages);
      if (URL.get('project') !== 'devil') {
        other_languages.splice(other_languages.indexOf('it'), 1);
        if (URL.get('ln') === 'it') {
          URL.update({
            ln: 'en'
          });
          this.cache.language = 'en';
        }
      }
      other_languages.splice(other_languages.indexOf(this.cache.language), 1);
      this.ui.find('.actual').remove();
      for (_i = 0, _len = other_languages.length; _i < _len; _i++) {
        other_language = other_languages[_i];
        nui = this.uis.languageTmpl.cloneTemplate();
        nui.attr("href", "#+ln=" + other_language);
        nui.text(other_language);
        this.ui.append(nui);
      }
      return URL.enableLinks(this.ui);
    } else {
      return this.getLanguage();
    }
  };

  return Language;

})(Widget);

portfolio.Download = (function(_super) {
  __extends(Download, _super);

  function Download() {
    this.sendFile = __bind(this.sendFile, this);
    this.getFile = __bind(this.getFile, this);
    this.relayout = __bind(this.relayout, this);
    this.bindUI = __bind(this.bindUI, this);
    this.UIS = {
      box: ".box",
      password: "input[type=password]",
      error: ".error"
    };
    this.ACTIONS = ["getFile", "hide"];
  }

  Download.prototype.bindUI = function(ui) {
    Download.__super__.bindUI.apply(this, arguments);
    $(window).resize(this.relayout);
    return this.relayout();
  };

  Download.prototype.relayout = function() {
    var box_height, window_height;
    window_height = $(window).height();
    box_height = this.uis.box.height();
    return this.uis.box.css({
      top: window_height / 2 - box_height / 2
    });
  };

  Download.prototype.getFile = function() {
    var kit_password;
    kit_password = this.uis.password.val();
    return $.ajax("/api/download", {
      type: "POST",
      data: {
        password: kit_password
      },
      success: this.sendFile,
      error: ((function(_this) {
        return function(msg) {
          return _this.uis.error.removeClass("hidden");
        };
      })(this))
    });
  };

  Download.prototype.sendFile = function(data) {
    this.uis.error.addClass("hidden");
    this.hide();
    return window.open(data, 'Download');
  };

  return Download;

})(Widget);

$(window).load(function() {
  if ($.browser.msie && parseInt($.browser.version, 10) < 9) {
    $("body > .wrap").addClass("hidden");
    $("body > .for-ie").removeClass("hidden");
  } else {
    $("body > .for-ie").addClass("hidden");
    $("body > .wrap").removeClass("hidden");
  }
  return Widget.bindAll();
});
