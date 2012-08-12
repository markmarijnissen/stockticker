class Stock extends Spine.Model
	@configure('Stock','name','symbol','currentPrice','openingPrice','percentage')
	@extend(Spine.Events)

	name: "langenaam.....dsadsadsad"				# e.g. "Barcleys"
	symbol: ""				# e.g. "BARC.L"
	currentPrice: 100213.10dollar	
	openingPrice: 0dollar
	percentage: -10.0percent

	->
		super ...
	
module.exports = Stock