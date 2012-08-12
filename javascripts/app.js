(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name) {
    var path = expand(name, '.');

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '"');
  };

  var define = function(bundle) {
    for (var key in bundle) {
      if (has(bundle, key)) {
        modules[key] = bundle[key];
      }
    }
  }

  globals.require = require;
  globals.require.define = define;
  globals.require.brunch = true;
})();

window.require.define({"controllers/app": function(exports, require, module) {
  var StockController, Stock, Sync, template, AppController;
  StockController = require('controllers/stock');
  Stock = require('models/stock');
  Sync = require('models/sync');
  template = require('views/app');
  Sync.start();
  AppController = (function(superclass){
    var prototype = extend$((import$(AppController, superclass).displayName = 'AppController', AppController), superclass).prototype, constructor = AppController;
    prototype.template = template;
    function AppController(){
      var saved, i$, ref$, len$, symbol, stock;
      this.onSortStop = bind$(this, 'onSortStop', prototype);
      this.onKeyUp = bind$(this, 'onKeyUp', prototype);
      this.onAddClick = bind$(this, 'onAddClick', prototype);
      superclass.apply(this, arguments);
      this.render();
      saved = Stock.all();
      if (saved.length === 0) {
        for (i$ = 0, len$ = (ref$ = ['BARC.L', 'LLOY.L', 'STAN.L']).length; i$ < len$; ++i$) {
          symbol = ref$[i$];
          this.add(symbol);
        }
      } else {
        saved.sort(function(a, b){
          return a.position > b.position;
        });
        for (i$ = 0, len$ = saved.length; i$ < len$; ++i$) {
          stock = saved[i$];
          this.add(stock.symbol);
        }
      }
    }
    prototype.events = {
      'click #add': 'onAddClick',
      'keyup #add-input': 'onKeyUp',
      "sortstop": "onSortStop"
    };
    prototype.add = function(symbol){
      var stock;
      if (typeof symbol === 'string' && symbol !== "" && !this.el.html().match(">" + symbol + "<")) {
        stock = new StockController({
          symbol: symbol
        });
        return $('#container').append(stock.el);
      }
    };
    prototype.remove = function(symbol){
      var ref$;
      return (ref$ = Stock.findByAttribute('symbol', symbol)) != null ? ref$.destroy() : void 8;
    };
    prototype.onAddClick = function(){
      return this.add($('#add-input').val());
    };
    prototype.onKeyUp = function(event){
      if (event.keyCode === 13) {
        return this.onAddClick();
      }
    };
    prototype.onSortStop = function(){
      return $(".stock").each(function(i, el){
        var stock;
        stock = Stock.findByAttribute('symbol', $(el).find('.symbol').text());
        stock.position = i;
        return stock.save();
      });
    };
    prototype.render = function(){
      this.html(this.template(this));
      return $('#container').sortable();
    };
    Stock.fetch();
    return AppController;
  }(Spine.Controller));
  module.exports = AppController;
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}});

window.require.define({"controllers/stock": function(exports, require, module) {
  var Stock, template, StockController;
  Stock = require('models/stock');
  template = require('views/stock');
  StockController = (function(superclass){
    var prototype = extend$((import$(StockController, superclass).displayName = 'StockController', StockController), superclass).prototype, constructor = StockController;
    prototype.template = template;
    prototype.className = 'stock';
    function StockController(atts){
      this.onCloseClick = bind$(this, 'onCloseClick', prototype);
      this.animate = bind$(this, 'animate', prototype);
      this.render = bind$(this, 'render', prototype);
      superclass.apply(this, arguments);
      this.model = Stock.findByAttribute('symbol', atts != null ? atts.symbol : void 8);
      if (this.model == null) {
        this.model = new Stock(atts);
        this.model = this.model.save();
      }
      this.model.bind('destroy', this.release);
      this.model.bind('change refresh', this.render);
      this.render();
    }
    prototype.events = {
      "click .close": "onCloseClick"
    };
    prototype.render = function(){
      this.html(this.template(this.model));
      if (this.previousPrice < this.model.currentPrice) {
        this.animate('increase');
      } else if (this.previousPrice > this.model.currentPrice) {
        this.animate('decrease');
      }
      return this.previousPrice = this.model.currentPrice;
    };
    prototype.animate = function(css){
      var $body, this$ = this;
      $body = this.$('.body');
      $body.addClass(css);
      return setTimeout(function(){
        return $body.removeClass(css);
      }, 1000);
    };
    prototype.onCloseClick = function(){
      return this.model.destroy();
    };
    return StockController;
  }(Spine.Controller));
  module.exports = StockController;
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}});

window.require.define({"index": function(exports, require, module) {
  var AppController;
  AppController = require('controllers/app');
  $(function(){
    var app;
    return app = new AppController({
      el: $('body')
    });
  });
}});

window.require.define({"models/stock": function(exports, require, module) {
  var Stock;
  Stock = (function(superclass){
    var prototype = extend$((import$(Stock, superclass).displayName = 'Stock', Stock), superclass).prototype, constructor = Stock;
    Stock.configure('Stock', 'name', 'symbol', 'currentPrice', 'openingPrice', 'percentage', 'position');
    Stock.extend(Spine.Events);
    Stock.extend(Spine.Model.Local);
    prototype.name = "";
    prototype.symbol = "";
    prototype.currentPrice = null;
    prototype.openingPrice = 0;
    prototype.percentage = -0;
    prototype.position = 0;
    function Stock(){
      superclass.apply(this, arguments);
    }
    prototype.validate = function(){
      this.symbol = this.symbol.toUpperCase();
      return null;
    };
    return Stock;
  }(Spine.Model));
  module.exports = Stock;
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}});

window.require.define({"models/sync": function(exports, require, module) {
  var Stock, onSuccess, onError, sync, timer, start, stop;
  Stock = require('models/stock');
  onSuccess = function(data){
    var symbol, atts, stock, results$ = [];
    if (data === "ERROR_NO_ARGUMENTS") {
      return this.onSyncError(data);
    } else {
      for (symbol in data) {
        atts = data[symbol];
        stock = Stock.findByAttribute('symbol', symbol);
        if (stock == null) {
          stock = new Stock({
            symbol: symbol
          });
        }
        import$(stock, atts);
        results$.push(stock.save());
      }
      return results$;
    }
  };
  onError = function(error){
    return console.error(error);
  };
  sync = function(){
    var stock, stocks, data;
    stocks = (function(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = Stock.all()).length; i$ < len$; ++i$) {
        stock = ref$[i$];
        results$.push(stock.symbol);
      }
      return results$;
    }()).join(',');
    data = {
      q: stocks
    };
    if (document.location.href.match(/randomize/)) {
      data.randomize = true;
    }
    if (stocks !== "") {
      return $.ajax({
        url: 'http://www.madebymark.nl/other/stockticker.php',
        data: data,
        dataType: 'jsonp',
        success: onSuccess,
        error: onError
      });
    }
  };
  timer = 0;
  start = function(){
    sync();
    return timer = setInterval(sync, 5000);
  };
  stop = function(){
    return clearInterval(timer);
  };
  module.exports = {
    start: start,
    stop: stop
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}});

window.require.define({"views/app": function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div id="container"></div><div id="menu"><input id="add-input" type="text"/><input id="add" type="button" value="Add"/></div>');
  }
  return buf.join("");
  };
}});

window.require.define({"views/stock": function(exports, require, module) {
  module.exports = function anonymous(locals, attrs, escape, rethrow, merge) {
  attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
  var buf = [];
  with (locals || {}) {
  var interp;
  buf.push('<div class="header"><div class="symbol">' + escape((interp = symbol) == null ? '' : interp) + '</div><div');
  buf.push(attrs({ 'title':(name), "class": ('name') }, {"title":true}));
  buf.push('>' + escape((interp = name) == null ? '' : interp) + '</div><div class="close">X</div></div><div class="body">');
  var price = ((currentPrice*1).toFixed(2));
  var percent = ((percentage*1).toFixed(2));
  if ( openingPrice == "N/A")
  {
  buf.push('<div class="loading">Invalid name</div>');
  }
  else if ( currentPrice > 0)
  {
  buf.push('<div class="price">' + escape((interp = price) == null ? '' : interp) + '</div>');
  if ( percentage > 0)
  {
  buf.push('<div class="percentage positive">+' + escape((interp = percent) == null ? '' : interp) + '%</div>');
  }
  else
  {
  buf.push('<div class="percentage negative">' + escape((interp = percent) == null ? '' : interp) + '% </div>');
  }
  }
  else
  {
  buf.push('<div class="loading">Loading...</div><div class="percentage"></div>');
  }
  buf.push('</div>');
  }
  return buf.join("");
  };
}});

