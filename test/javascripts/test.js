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

window.require.define({"test/app_test": function(exports, require, module) {
  var App;
  App = require('controllers/app');
  describe('App', function(x){
    var app;
    app = null;
    beforeEach(function(){
      return app = new App();
    });
    afterEach(function(){
      return app.release();
    });
    it('shows Stock-items when they are added', function(){
      app.add("BARC.L");
      return expect(app.html()).to.match(/BARC\.L/);
    });
    return it('can remove Stock-items', function(){
      app.add("BARC.L");
      app.remove("BARC.L");
      return expect(app.html).to.not.match(/BARC\.L/);
    });
  });
}});

window.require.define({"test/stock_test": function(exports, require, module) {
  var StockController;
  StockController = require('controllers/stock');
  describe('Stock', function(x){
    var stock;
    stock = null;
    beforeEach(function(){
      return stock = new StockController({
        symbol: 'TEST'
      });
    });
    it('renders the stock template', function(){
      return expect($(stock.el).find('div.header')).to.be.ok;
    });
    it('shows "loading" when no information has been retrieved', function(){
      expect($(stock.el).find('.loading')).to.be.not.empty;
      return expect($(stock.el).find('.loading').html()).to.match(/loading/i);
    });
    it('show positive percentages in "green"', function(){
      var x$, stock;
      x$ = stock = new StockController;
      ({
        symbol: 'TEST',
        currentPrice: 10,
        percentage: 0.1
      });
      return expect($(stock.el).find('.percentage').attr('class')).to.match(/positive/);
    });
    it('show negative percentages in "red"', function(){
      var x$, stock;
      x$ = stock = new StockController;
      ({
        symbol: 'TEST',
        currentPrice: 10,
        percentage: -0.1
      });
      return expect($(stock.el).find('.percentage').attr('class')).to.match(/negative/);
    });
    return it("releases the Stock element when the Stock model is destroyed", function(){
      var parentElement;
      parentElement = $('<div>');
      parentElement.append(stock.el);
      expect(parentElement.html()).to.not.equal("");
      stock.model.destroy();
      return expect(parentElement.html()).to.equal("");
    });
  });
}});

window.require.define({"test/test-helpers": function(exports, require, module) {
  
  module.exports = {
    expect: require('chai').expect,
    sinon: require('sinon'),
    $: require('jquery')
  };
  
}});

window.require('test/app_test');
window.require('test/stock_test');
