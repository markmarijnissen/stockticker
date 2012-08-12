StockController = require('controllers/stock')
Stock = require('models/stock')
template = require('views/app')

class AppController extends Spine.Controller
	template: template 

	->
		super ...
		@append $('<div id="menu">')
		@append $('<div id="container">')
		saved = Stock.all()
		if saved.length is 0
			[@add symbol for symbol in <[BARC.L LLOY.L STAN.L]>] 
		else
			saved.sort (a,b) -> a.position > b.position
			[@add stock.symbol for stock in saved]
		@render!
		

	events:
		'click #add': 'onAddClick'	
		'keyup #add-input': 'onKeyUp'	
		"sortstop": "onSortStop"

	# create a new StockController, and append the element
	add: (symbol) -> 
		if typeof symbol is 'string' and symbol isnt "" and not @el.html().match(">#symbol<")
			stock = new StockController(symbol:symbol)
			$('#container').append stock.el

	# find and destroy the Stock, which destroys the controller, which destroys the element.
	remove: (symbol) -> Stock.findByAttribute('symbol',symbol)?.destroy()

	onAddClick: ~> @add $('#add-input').val!

	onKeyUp: (event) ~> if event.keyCode is 13 then @onAddClick!

	onSortStop: ~>
		$ ".stock" .each (i,el) ->
			stock = Stock.findByAttribute('symbol',$ el .find '.symbol' .text!)
			stock.position = i
			stock.save!

	render: ->
		$ '#menu' .html @template(@)
		$ '#container' .sortable!

	Stock.fetch()
					
module.exports = AppController