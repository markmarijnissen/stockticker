Stock = require('models/stock')
template = require('views/stock')

class StockController extends Spine.Controller
	template: template
	className: 'stock'

	# constructor
	(atts) ->
		super ...
		# bind to existing model if exists
		@model = Stock.findByAttribute 'symbol',atts?.symbol
		# otherwise, create a fresh model & save it to global collection
		unless @model?
			@model = new Stock atts
			@model = @model.save! 
		# release element upon model's destruction
		@model.bind 'destroy',@release
		# re-render view upon model change
		@model.bind 'change refresh',@render
		# render upon creation
		@render!

	events: 
		"click .close": "onCloseClick"

	# render the template with the Stock model
	render: ~> 
		@html @template(@model)
		# animate a flash when the price changes
		if @previousPrice < @model.currentPrice then 
			@animate 'increase'
		else if @previousPrice > @model.currentPrice
			@animate 'decrease'
		@previousPrice = @model.currentPrice

	animate: (css) ~>
		$body = @$ '.body'
		$body.addClass css		
		setTimeout (~> $body.removeClass css),1000ms
		# old browser just briefly show an alternate background-color
		# modern browsers use the animation properties of the class to animate a flash

	onCloseClick: ~> @model.destroy!

module.exports = StockController