class Stock extends Spine.Model
	@configure('Stock','name','symbol','currentPrice','openingPrice','percentage')
	@extend(Spine.Events)

	name: ""				# e.g. "Barcleys"
	symbol: ""				# e.g. "BARC.L"
	currentPrice: 0dollar	
	openingPrice: 0dollar
	percentage: 0percent

	->
		super ...
	
module.exports = Stock