StockController = require('controllers/stock')
Stock = require('models/stock')
Sync = require('models/sync')
template = require('views/app')

Sync.start!

class AppController extends Spine.Controller
	template: template 

	->
		super ...
		# render base layout
		@render!
		# retrieve saved stock instances, if any
		console.log('fetch',Stock.fetch())
		saved = Stock.all()
		#nothing found, just add defaults
		if saved.length is 0
			[@add symbol,yes for symbol in <[BARC.L LLOY.L STAN.L]>] 
		# instanced found, add them
		else
			# sort stock instances based on position from drag & drop
			saved.sort (a,b) -> a.position > b.position
			[@add stock.symbol,yes for stock in saved]
		
	# bind events
	events:
		'click #add': 'onAddClick'	
		'keyup #add-input': 'onKeyUp'	
		"sortstop": "onSortStop"

	# create a new StockController, and append the element
	add: (symbol,override = no) -> 
		# only add if symbol is valid and not added before
		# the 'added-before' check is a bit dirty but effective; it checks if 
		# the symbol occurs in the HTML
		if typeof symbol is \string and (override or Stock.findByAttribute('symbol',symbol.toUpperCase!) is null)
			stock = new StockController(symbol:symbol)
			$('#container').append stock.el
			@savePosition!

	# find and destroy the Stock, which destroys the controller, which destroys the element.
	remove: (symbol) -> Stock.findByAttribute('symbol',symbol)?.destroy()

	# link user-input to @add
	onAddClick: ~> @add $('#add-input').val!
	onKeyUp: (event) ~> if event.keyCode is 13 then @onAddClick!

	# update & save positions when sorting ends
	savePosition: ~>
		# iterate over stock elements
		$ ".stock" .each (i,el) ->
			# find the stock element based on value of .symbol div
			stock = Stock.findByAttribute('symbol',$ el .find '.symbol' .text!)
			# set & save position
			stock.position = i
			stock.save!

	# render menu from template
	render: ->
		@html @template(@)		
		$ '#container' .sortable!
					
module.exports = AppController