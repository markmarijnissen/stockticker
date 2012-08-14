StockController = require('controllers/stock')

describe 'Stock', (x) -> 
	stock = null
	beforeEach ->
		stock := new StockController symbol:'TEST'

	it 'renders the stock template',->
		expect $(stock.el).find('div.header') .to.be.ok

	it 'shows "loading" when no information has been retrieved',->
		expect $(stock.el).find('.loading') .to.be.not.empty # it exists when $ is not empty
		expect $(stock.el).find('.loading').html! .to.match /loading/i # and it says loading

	it 'show positive percentages in "green"',->
		stock = new StockController(symbol: 'TEST')
		stock.model.currentPrice = 10 # initialize stock
		stock.model.percentage = 0.1 # with positive percentage
		stock.render!

		expect stock.model.percentage .to.be.above 0
		expect $(stock.el).find('.percentage').attr('class') .to.match /positive/

	it 'show negative percentages in "red"',->
		stock = new StockController(symbol: 'TEST')
		stock.model.currentPrice = 10 # initialize stock
		stock.model.percentage = -0.1 # with positive percentage
		stock.render!

		expect stock.model.percentage .to.be.below 0
		expect $(stock.el).find('.percentage').attr('class') .to.match /negative/

	it 'animates a positive change with a green flash',(done)->
		stock.model.currentPrice = 10
		stock.render!
		$body = $(stock.el).find('.body')
		expect $body.attr('class') .to.match /increase/
		setTimeout (-> expect $body.attr('class') .to.not.match /increase/; done!),1050ms

	it 'animates a negative change with a red flash',(done) ->
		stock.model.currentPrice = -10
		stock.render!
		$body = $(stock.el).find('.body')
		expect $body.attr('class') .to.match /decrease/
		setTimeout (-> expect $body.attr('class') .to.not.match /decrease/; done!),1050ms

	it 'does not animate no change',->
		stock.render!
		stock.render!
		expect $(stock.el).find('.body').attr('class') .to.not.match /(increase|decrease)/

	it "releases the Stock element when the Stock model is destroyed", ->
		# create a dummy parent element
		parentElement = $('<div>')		
		# append our stock to the parent
		parentElement.append stock.el   
		expect parentElement.html! .to.not.equal ""
		# invoke destruction
		stock.model.destroy()
		# test
		expect parentElement.html! .to.equal ""
