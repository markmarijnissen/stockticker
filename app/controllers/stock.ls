view = require('views/stock')

class StockController extends Spine.Controller
	view: view
	
	->
		super ...

	render: ->
		@html <| view <| render

module.exports = StockController