Stock = require('models/stock')
template = require('views/stock')

class StockController extends Spine.Controller
	template: template

	# constructor
	(symbol) ->
		super ...
		# create a new Stock model
		@stock = new Stock(symbol)
		# render it immediatly
		@render()

	# render the template with the Stock model
	render: ->
		@html @template(@stock)

module.exports = StockController