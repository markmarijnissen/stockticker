App = require('controllers/app')

describe 'App', (x) ->
	app = null

	beforeEach ->
		app := new App()

	it 'shows Stock-items when they are added', ->
		app.add "BARC.L"
		expect app.el.html() .to.match /BARC\.L/

	it 'can remove Stock-items', ->
		app.add "BARC.L"
		app.remove "BARC.L"
		expect app.el.html() .to.not.match /BARC\.L/