App = require('controllers/app')
Stock = require('models/stock')

describe 'App', (x) ->
	app = null

	beforeEach ->
		app := new App()

	afterEach ->
		app.release!

	it 'can only add stock-items once', ->
		app.add "BARC.L"
		app.add "BARC.L"
		app.add "BARC.L"
		items = Stock.findAllByAttribute 'symbol','BARC.L'

		expect items.length .to.equal 1

	it 'shows Stock-items when they are added', ->
		app.add "BARC.L",true
		expect app.el .to.be.ok
		expect app.el.html! .to.match /BARC\.L/

	it 'can remove Stock-items', ->
		app.add "BARC.L",true
		expect app.el.html! .to.match /BARC\.L/
		$(app.el).find ".close" .trigger 'click'
		expect app.el.html! .to.not.match /BARC\.L/