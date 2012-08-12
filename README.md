Stock Ticker Tutorial
===============
Stock Ticker is a modern web-application build using the following technology:

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
First, we will create the necessary Stock MVC. While Brunch supports generators and scaffolding,
I haven't created generators for Spine.js with LiveScript yet, so we'll have to do this manually.

We have a `stock` model, which retrieves information of one particular stock. 
We can write an initial model in `app/models/stock.ls`:
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
`@configure` tells Spine which attributes the model has. This is used troughout spine.js for storing in localStorage, ajax-request, etc. 

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
As you can see, the view displays loading when the stock information is not yet fetched, and it adds a 'positive' or 'negative' class to the percentage depending on its value.

Finally, we create a controller to connect model with the view:
`app/controllers/stock.ls`:
```CoffeeScript
Stock = require('models/stock')
template = require('views/stock')

class StockController extends Spine.Controller
	template: template

	# constructor
	(symbol) ->
		super ...
		# create a new Stock model
		# Spine Model Constructor accepts objects, which set the initial attributes of the instance.
		@model = new Stock(symbol:symbol) 
		# render it immediatly
		@render()

	# render the template with the Stock model
	render: ->
		@html template(@model)

module.exports = StockController
```

### Testing

We already have quite some behavior that we should test to verify it works correctly. 
Brunch uses Mocha. We can test by executing `brunch test` or by using the browser runner at [localhost:3333/test](http://localhost:3333/test).

Testing is done with [chai's](http://chaijs.com/api/bdd/) `expect` grammer, which is wrapped in TDD/BDD style 'describe' and 'it' functions.

So we create 'test/stock_test.ls' to test our Model, View and Controller:

```CoffeeScript
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
```
Note: We must use `describe, (x) ->` to prevent `it` from being shadowed. LiveScript automatically inserts `it` as first argument of a function when `it` is used in the function body. In this case we want to refer to the global function!

Step 2. The Main App
--------------------
Our main app simply displays (and controls) a collection of Stock-objects, so we suffice with only a controller:
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
		expect parentElement.html() .to.not.equal ""
		# invoke destruction
		stock.model.destroy()
		# test
		expect parentElement.html() .to.equal ""
```

And we test the addition and removal of elements in `test/app_test.ls`
```CoffeeScript
App = require('controllers/app')

describe `App`, (x) ->
	app = null

	beforeEach, ->
		app := new App()

	it `shows Stock-items when they are added`, ->
		app.add "BARC.L"
		expect app.html() .to.match /BARC\.L/

	it `can remove Stock-items`, ->
		app.add "BARC.L"
		app.remove "BARC.L"
		expect app.html .to.not.match /BARC\.L/
```
When you run `brunch test`, you will see the test fails! This is why we test, to write down expected behavior, and to find when our app behaviors differently.

This error is caused because `Stock.findByAttribute` still manages to return a Stock-instance. With every `add` we create a new Stock-instance, even if the symbol already exists in the global collection! So we need to use the existing Stock-instance when we create a Stock-controller. We can do this by modifying the constructor:

```CoffeeScript
	# bind to existing model if exists
	@model = Stock.findByAttribute('symbol',symbol)
	# otherwise, create a fresh model
	@model = new Stock(symbol:symbol) unless @model?
```

Now the tests will pass!

Step 3: Styling
===============
We style the stock-view in `app/styles/stock.less`. We need to add `className: 'stock'` to add `stock` to the StockController element. Using LESS mixins, we can create a function that generates everything based on a @size argument. Combined with media-queries, we can easily create a responsive design, i.e:
```LESS
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
I also used common LESS mixins from [lesselements.com](http://lesselements.com/) to create gradients, rounded borders, etc. Note that "_elements.less" is prefixed with "_". This ensures Brunch ignores the file and does not compile it, because it is already included in stock.less.

Step 4: Server Functionality
============================
I want Stock to work with both the original Yahoo Finance servers, as well as my own JSON API from a PHP-server. So instead of adding functions directly to the Stock-model, I create mixins. This way, I can add the mixin of choice to my Stock model.

It will be the most efficient to fetch all the data in one call, so that is why the server-call will be a static method. 

