Stock Ticker Tutorial
===============
Stock Ticker is a modern web-application which displays stock prices in real-time.
It is build using the following technology:

* **jQuery** and **[Spine.js](http://www.spinejs.com)**, a MCV framework
* **[LiveScript](http://gkz.github.com/LiveScript/)**, which compiles into JavaScript.
* **[Jade](https://github.com/visionmedia/jade#readme)**, a template engine.
* **[LESS](http://www.lesscss.org)**, which compiles into CSS.
* **[Brunch](http://brunch.io)**, a build tool.

Brunch can also watch your files and run a local server, which means LiveScript, Jade and LESS get continuously compiled, concatenated and minified, and you only have to refresh the browser to view the app.

All these tools run on [Node.js](http://nodejs.org/)

Step 0. Installation
--------------------
1. Install [Node.js](http://nodejs.org)
1. Install Brunch using the **N**ode **P**ackage **M**anager: `npm install brunch -g` 
1. Clone this repository: `git clone ...`
1. Install missing node.js packages with: `npm install`

Now we have Node.js, the `brunch` command-line tool, and a standard directory layout:
```
|-- app
|   |-- assets			static resources, such as images
|   |-- controllers		.ls for controllers 
|   |-- models			.ls for models
|   |-- styles			.less stylesheets
|   '-- views			.jade view templates
|
|-- public				Contains the compiled web app
|
|-- test				
|   |-- assets			Mocha browser test runner (don't touch)
|   '-- vendor			Mocha libraries & stylesheets (don't touch)
|
|-- vendor
|   |-- scripts			jQuery
|   |   '-- spine		spine.js libraries
|   '-- styles 			contains 'normalize.css' & 'helpers.css'
|
|-- package.json 		Node.js package dependencies (NPM)
'-- config.coffee 		Brunch configuration
```
Try run `brunch watch -server` and navigate to [http://localhost:3333](http://localhost:3333). 

Step 1. Stock MVC
-----------------
First, we create a model, view and controller for a single stock item.

`app/models/stock.ls`:

```LiveScript
class Stock extends Spine.Model
	@configure('Stock','name','symbol','currentPrice','openingPrice','percentage')
	name: ""				# e.g. "Barcleys"
	symbol: ""				# e.g. "Barc.l"
	currentPrice: 0dollar	
	openingPrice: 0dollar
	percentage: 0percent

	->
		super ...
	
module.exports = Stock
```
`@configure` defines the class name and attributes. This is used troughout Spine.js, for example when saving and searching instances in the global Stock collection.

The model will be displayed with a stock view:
`app/views/stock.jade`
```jade
.header
	.symbol #{symbol}
	.name #{name}
.body
	if price > 0
		.price #{price}
		percentageClass = percentage > 0? 'positive' : 'negative'
		.percentage(class=percentageClass) #{percentage}
	else
		.loading Loading...
		.percentage
```
As you can see, the template has a little display logic:
* It will display "Loading" when the stock has not retrieved.
* It adds 'positive' or 'negative' styling to the percentage.
* It formats the numbers

Finally, a controller connects the view with the model. Controllers deal with rendering templates, responding to DOM events, and they keep the model and view in sync. Spine.js controllers have a DOM element associated with it, and some convenience methods to manipulate it.

```CoffeeScript
# /app/controllers/stock.ls

Stock = require('models/stock')
template = require('views/stock')

class StockController extends Spine.Controller
	template: template
	className: 'stock'

	# constructor
	(attrs) ->
		super ...
		symbol = attrs.symbol
		# bind to existing model if exists
		@model = Stock.findByAttribute 'symbol',symbol
		# otherwise, create a fresh model & save it to global collection
		unless @model?
			@model = new Stock symbol:symbol
			@model = @model.save! 
		# re-render view upon model change
		@model.bind 'change',@render
		# render upon creation
		@render!

	# render the template with the Stock model
	render: ~> @html @template(@model)

module.exports = StockController
```



Step 2. Testing
---------------
We should test if our app behaves as expected. We use [Mocha](http://visionmedia.github.com/mocha/) as testing framework. Test are executed using `brunch test` or by using the browser runner at [localhost:3333/test](http://localhost:3333/test).

`brunch test` is run in Node.js, and calls `test_helpers.coffee` to include necessary libraries, such as 
[chai.js'](http://chaijs.com/api/bdd/) 'expect' grammar.

```CoffeeScript
# /test/stock_test.ls

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
		stock = new StockController
			symbol: 'TEST'
			currentPrice: 10 # initialize stock
			percentage: 0.1 # with positive percentage

		expect $(stock.el).find('.percentage').attr('class') .to.match /positive/

	it 'show negative percentages in "red"',->
		stock = new StockController
			symbol: 'TEST'
			currentPrice: 10 # initialize stock
			percentage: -0.1 # with positive percentage

		expect $(stock.el).find('.percentage').attr('class') .to.match /negative/
```
Note: We must use `(x) ->` to prevent `it` from being shadowed. LiveScript automatically inserts `it` as first argument of a function when `it` is used in the function body. In this case we want to refer to the global function!

Step 2. The App Controller
--------------------
Our app simply displays (and controls) a collection of Stock-objects, so we suffice with only a controller:
```CoffeeScript
StockController = require('controllers/stock')

class AppController extends Spine.Controller
	->
		super ...
		@bind 'change',@render
		[@add symbol for symbol in <[BARC.L LLOY.L STAN.L]>]

	# create a new StockController, and append the element
	add: (symbol) -> 
		stock = new StockController(symbol)
		stock.model.save() 
		@append stock

	# find and destroy the Stock, which destroys the controller, which destroys the element.
	remove: (symbol) -> Stock.findByAttribute('symbol',symbol).destroy()
					
module.exports = AppController
```
Note how we call `save` to save the stock-instance to the global Stock collection. 
This allows us to find and remove the stock-instance later on with `Stock.findByAttribute`

To remove the element upon destruction of the Stock model instance, we need to bind the 
destroy event of the model to the release function of the controller.

So we add to the StockController constructor:
```CoffeeScript
	@stock.bind 'destroy',@release
```

### Testing:
We test release upon destruction in `test/stock_test.ls`:
```CoffeeScript
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
```

And we test the addition and removal of elements:
```CoffeeScript
# test/app_test.ls
App = require('controllers/app')

describe 'App', (x) ->
	app = null

	beforeEach ->
		app := new App()

	afterEach ->
		app.release!

	it 'shows Stock-items when they are added', ->
		app.add "BARC.L"
		expect app.html() .to.match /BARC\.L/

	it 'can remove Stock-items', ->
		app.add "BARC.L"
		app.remove "BARC.L"
		expect app.html .to.not.match /BARC\.L/
```

Step 3: Styling
===============
I used common LESS mixins from [lesselements.com](http://lesselements.com/) to create gradients, rounded borders, etc. Note that "_elements.less" is prefixed with "_". This ensures Brunch ignores the file and does not compile it, because it is already included in stock.less.

With LESS, it is also easy to create a responsive layout. You simply create a mixin that takes the size as argument, and then call this mixin with different sizes in media-queries. For example:

```LESS
// simplified version from app/styles/stock.less

@import "_elements.less"

.stock-layout(@size) {
	width: @size;
	height: @size;
}

.stock {
	.stock-layout(200px)
}

@media(max-width: 640px) {
	.stock {
		.stock-layout(150px)
	}
}
```

Step 4: Server Functionality
============================
Stock Prices are fetched from a JSON-API run served by a PHP-script on the server. We can save some requests by combining all stock-prices into a single request.

We saved stock-items in the global Stock collection, so we can easily list the symbols we need to request:
```CoffeeScript
	stocks = [stock.symbol for stock in Stock.all!].join ','
```

We use jQuery to perform an AJAX-request:
```CoffeeScript
	$.ajax(
		url: 'http://www.madebymark.nl/other/stockticker.php'
		data: { q: stocks }
		dataType: 'jsonp' #cross-domain, so JSONP
	).success (data) ~>
		for symbol,atts of data
			# try to find existing stock
			stock = Stock.findByAttribute 'symbol',symbol
			# otherwise, create a new stock-instance
			stock = new Stock(symbol:symbol) unless stock?
			# copy attributes to stock
			stock <<< atts
			# save stock to update everything 
			stock.save!
	.fail (error) ~>
		@trigger 'error','ajax',error
```