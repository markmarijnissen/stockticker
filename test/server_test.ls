describe "Server", (x) ->

	it "gives a correct response", (done)->
		$.ajax do
			url: 'http://data.madebymark.nl/other/stockticker.php'
			data: q: "BARC.L,GOOG,XXX"
			dataType: 'jsonp' #cross-domain, so JSONP
			success: (data) -> 
				expect data .to.have.property "BARC.L"
				expect data .to.have.property "GOOG"
				expect data .to.have.property "XXX"
				
				xxx = data.XXX
				goog = data.GOOG

				expect xxx .to.have.property "openingPrice","N/A"
				expect goog.currentPrice .to.be.a "number"
				expect goog.percentage .to.be.a "number"
				expect goog .to.have.property "symbol","GOOG"
				expect goog .to.have.property "name","Google Inc."
				done!

	it "gives an error when no arguments are supplied", (done) ->
		$.ajax do
			url: 'http://data.madebymark.nl/other/stockticker.php'
			dataType: 'jsonp' #cross-domain, so JSONP
			success: (data) -> 
				expect data .to.equal "ERROR_NO_ARGUMENTS"
				done!