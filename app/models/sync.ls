Stock = require('models/stock')

# sync success callback	
onSuccess = (data) ->
	if data is "ERROR_NO_ARGUMENTS" then onError data
	else for symbol,atts of data
		# try to find existing stock
		stock = Stock.findByAttribute 'symbol',symbol
		# otherwise, create a new stock-instance
		stock = new Stock(symbol:symbol) unless stock?
		# copy attributes to stock
		stock <<< atts
		# save stock to update everything 
		stock.save()

# sync error callback
onError = (error) -> console.error error

# sync itself
sync = ->	
	# join all stock symbols with a ','
	stocks = [stock.symbol for stock in Stock.all!].join ','
	data = q: stocks
	# a little hack; but #randomize in the URL and PHP will add noise
	# to the stock, therefore enabling you to see the animations on weekends
	data.randomize = true if document.location.href.match /randomize/
	# when we have any stock, perform ajax
	if stocks isnt "" 
		$.ajax do
			url: 'http://www.madebymark.nl/other/stockticker.php'
			data: data
			dataType: 'jsonp' #cross-domain, so JSONP
			success: onSuccess
			error: onError

# timing 
timer = 0;
start = -> 
	sync!
	timer := setInterval(sync,5000ms)
stop = -> clearInterval timer

module.exports = 
		start: start
		stop: stop
		sync: sync