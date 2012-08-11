StockController = require('controllers/stock')
Stock = require('models/stock')

class AppController extends Spine.Controller
	->
		super ...
		@bind 'change',@render
		[@add symbol for symbol in <[barc ad cla]>]

	# create a new StockController, and append the element
	add: (symbol) -> 
		if Stock.findByAttribute('symbol',symbol) is null
			stock = new StockController(symbol)
			stock.model.save()
			@append stock
		else
			@trigger 'error',"#symbol already exists!"

	# find and destroy the Stock, which destroys the controller, which destroys the element.
	remove: (symbol) -> Stock.findByAttribute('symbol',symbol)?.destroy()
					
module.exports = AppController