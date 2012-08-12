class Stock extends Spine.Model
	@configure('Stock','name','symbol','currentPrice','openingPrice','percentage','position')
	@extend(Spine.Events)
	@extend(Spine.Model.Local)

	name: ""				# e.g. "Barcleys"
	symbol: ""				# e.g. "BARC.L"
	currentPrice: null	
	openingPrice: 0dollar
	previousPrice: 0dollar
	percentage: -0percent
	position: 0

	->
		super ...

	validate: ->
		@symbol = @symbol.toUpperCase!
		null

	# retrieves latest stock info from PHP
	@sync = ~>
		stocks = [stock.symbol for stock in Stock.all!].join ','
		if stocks isnt "" then $.ajax do
			url: 'http://www.madebymark.nl/other/stockticker.php'
			data: { q: stocks }
			dataType: 'jsonp' #cross-domain, so JSONP
			success: @onSyncSuccess
			error: @onSyncError
	
	@onSyncSuccess = (data) ~>
		if data is "ERROR_NO_ARGUMENTS"
			@trigger 'error',data
		else for symbol,atts of data
			# try to find existing stock
			stock = Stock.findByAttribute 'symbol',symbol
			# otherwise, create a new stock-instance
			stock = new Stock(symbol:symbol) unless stock?
			# copy attributes to stock
			stock <<< atts
			# save stock to update everything 
			stock.save()

	@onSyncError = (error) ~> @trigger 'error','ajax',error

	@startSync = ~> 
		@sync()
		@timer = setInterval(@sync,5000ms)

	@stopSync = ~> clearInterval @timer

	@startSync()
		
module.exports = Stock