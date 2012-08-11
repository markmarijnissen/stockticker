StockController = require('controllers/stock')

describe 'Stock', (x) -> 
	stock = null
	beforeEach ->
		stock := new StockController('test')

	it 'renders the stock template',->
		expect $(stock.el).find('div.header') .to.be.ok

	it 'shows "loading" when no information has been retrieved',->
		expect $(stock.el).find('.loading') .to.be.not.empty # it exists when $ is not empty
		expect $(stock.el).find('.loading').html() .to.match /loading/i # and it says loading

	it 'show positive percentages in "green"',->
		stock.model.currentPrice = 10 # initialize stock
		stock.model.percentage = 0.1 # with positive percentage
		stock.render()
		expect $(stock.el).find('.percentage').attr('class') .to.match /positive/

	it 'show negative percentages in "red"',->
		stock.model.currentPrice = 10 # initialize stock
		stock.model.percentage = -0.1 # with negative percentage
		stock.render()		
		expect $(stock.el).find('.percentage').attr('class') .to.match /negative/

	it "releases the Stock element when the Stock model is destroyed", ->
		# create a dummy parent element
		parentElement = $('<div>')		
		# append our stock to the parent
		parentElement.append stock.el   
		expect parentElement.html() .to.not.equal ""
		# invoke destruction
		stock.model.destroy()
		# test
		expect parentElement.html() .to.equal ""
