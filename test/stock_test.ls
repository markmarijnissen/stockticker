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

	it 'show positive percentages "green"',->
		stock.stock.currentPrice = 10 # initialize stock
		stock.stock.percentage = 0.1 # with positive percentage
		stock.render()
		expect $(stock.el).find('.percentage').attr('class') .to.match /positive/

	it 'show negative percentages "red"',->
		stock.stock.currentPrice = 10 # initialize stock
		stock.stock.percentage = -0.1 # with negative percentage
		stock.render()		
		expect $(stock.el).find('.percentage').attr('class') .to.match /negative/