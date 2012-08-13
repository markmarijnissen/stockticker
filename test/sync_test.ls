Stock = require('models/stock')
Sync = require('models/sync')


describe "Sync", (x) ->
	it "updates the stock collection", (done) ->
		# destroy everything
		Sync.stop!
		Stock.deleteAll!
		# check if everything is gone
		expect Stock.all! .to.be.empty

		updateCallback = -> 
			updateCount = 0
			for stock in Stock.all!
				if stock.currentPrice > 0 then
					updateCount++
			if updateCount is 3 then done!

		# add three frech stock instances
		for symbol in <[GOOG BARC.L CCC]>
			stock = new Stock symbol:symbol
			stock.save!
			stock.bind "update",updateCallback

		# check if they are added
		expect Stock.all().length .to.equal 3

		# SYNC
		Sync.sync!


