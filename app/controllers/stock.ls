Stock = require('models/stock')
template = require('views/stock')

class StockController extends Spine.Controller
	template: template

	# constructor
	(symbol = "") ->
		super ...
		# bind to existing model if exists
		@model = Stock.findByAttribute('symbol',symbol)
		# otherwise, create a fresh model
		@model = new Stock(symbol:symbol) unless @model?
		# release element upon model's destruction
		@model.bind 'destroy',@release
		# render it immediatly
		@render()

	# render the template with the Stock model
	render: -> @html @template(@model)

module.exports = StockController