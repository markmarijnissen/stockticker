class Stock extends Spine.Model
	@configure('Stock','name','symbol','currentPrice','openingPrice','percentage','position')
	@extend(Spine.Events)
	@extend(Spine.Model.Local) if Spine.Model.Local?

	name: ""				# e.g. "Barcleys"
	symbol: ""				# e.g. "BARC.L"
	currentPrice: null	
	openingPrice: 0dollar
	percentage: -0percent
	position: 0

	->
		super ...

	validate: ->
		@symbol = @symbol.toUpperCase!
		null
		
module.exports = Stock