Stock Ticker Tutorial
===============
![Screenshot](http://markmarijnissen.github.com/thegateway/img/screenshot.png)

View [demo here](http://markmarijnissen.github.com/thegateway).

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
|-- server 				Contains server-side PHP code
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

```CoffeeScript
# app/models/stock.ls
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

	# add stock item
	add: (symbol) -> 
		# only add if symbol is valid and not added before
		# the 'added-before' check is a bit dirty but effective; it checks if 
		# the symbol occurs in the HTML
		if typeof symbol is 'string' and symbol isnt "" and not @el.html().match(">#symbol<") 
			stock = new StockController(symbol:symbol)
			@append stock.el

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
Step 3: Styling
===============
I used common LESS mixins from [lesselements.com](http://lesselements.com/) to create gradients, rounded borders, etc. Note that "`_elements.less`" is prefixed with "`_`". This ensures Brunch ignores the file and does not compile it, because it is already included in stock.less.

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
# sync
sync = ->	
	# join all stock symbols with a ','
	stocks = [stock.symbol for stock in Stock.all!].join ','
	data = q: stocks
	if stocks isnt "" 
		$.ajax do
			url: 'http://www.madebymark.nl/other/stockticker.php'
			data: data
			dataType: 'jsonp' #cross-domain, so JSONP
			success: onSuccess
			error: onError

onSuccess = (data) ->
	if data is "ERROR_NO_ARGUMENTS" then @onSyncError data
	else for symbol,atts of data
		# try to find existing stock
		stock = Stock.findByAttribute 'symbol',symbol
		# otherwise, create a new stock-instance
		stock = new Stock(symbol:symbol) unless stock?
		# copy attributes to stock
		stock <<< atts
		# save stock to update everything 
		stock.save()

# sync error callback
onError = (error) -> console.error error
```

The Server-Side PHP is a simple script that CURLs the Yahoo Server and converts the CSV data to JSON.

Step 5: Animations
==================
With LESS mixins, I have created two CSS3 animations with all the proper vendor-prefixes.

We need to update our render function to invoke these animations when a change is detected:
```CoffeeScript
	# render the template with the Stock model
	render: ~> 
		@html @template(@model)
		# animate a flash when the price changes
		if @previousPrice < @model.currentPrice then 
			@animate 'increase'
		else if @previousPrice > @model.currentPrice
			@animate 'decrease'
		@previousPrice = @model.currentPrice
```
This is simply done by storing the price of the previous render, and calling the appropriate
animation when the current price changes.

The animation function adds the animation class, triggering the animation. It also **removes** the class when the mediation is done. This serves a double purpose: It ensures the animation will be played when the next price change occurs, but it also supports old browsers. When the browser can't animate, the Stock element will simply show a different background for a brief moment.
```
	animate: (css) ~>
		$body = @$ '.body'
		$body.addClass css		
		setTimeout (~> $body.removeClass css),1000ms
```

Step 6: Extra's
==================
An entire framework might seem a bit heavy for a simple app, but it proves a solid foundation to build on.You could easily create an entire widget-dashboard from this app!

Here are some extra's that were easy to add:

### Persistence

Simply by adding `@extend(Spine.Model.Local)` to our Stock model saves the instances to localStorage.
By calling `Stock.fetch()` upon construction, we retrieve the instances. This saves us waiting for the stock information to come in.

### Sortable

By adding jQuery-UI's sortable plugin, it is easy to drag & drop stock-items to a new position. Simply call `$(...).sortable()` on the container of the Stock-elements.

To remember this order after a reload, we number & save the position of the stock-elements:
```CoffeeScript
	# update & save positions when sorting ends
	onSortStop: ~>
		# iterate over stock elements
		$ ".stock" .each (i,el) ->
			# find the stock element based on value of .symbol div
			stock = Stock.findByAttribute('symbol',$ el .find '.symbol' .text!)
			# set & save position
			stock.position = i
			stock.save!
```

When restoring, we sort our stock-items on this position:
```CoffeeScript
	saved.sort (a,b) -> a.position > b.position
```

### Add & Delete

Our app-controller already features addition and removal of stock instances - 
we only have to create a GUI to leverage this.

So we add an 'X' to the Stock-view, and we create an app-layout:
```Jade
// app/views/app.jade
#container
#menu
	input#add-input(type="text")
	input#add(type="button",value="Add")
```

And we bind this to adding stock-items:
```CoffeeScript
# bind events
	# app/controllers/app.ls
	events:
		'click #add': 'onAddClick'	
		'keyup #add-input': 'onKeyUp'	
		"sortstop": "onSortStop"

	onAddClick: ~> @add $('#add-input').val!
	onKeyUp: (event) ~> if event.keyCode is 13 then @onAddClick!

	# app/controllers/stock.ls
	events: 
		"click .close": "onCloseClick"

	onCloseClick: ~> @model.destroy!
```

With user-input we can suddenly have invalid names, so we update the Stock-view to show this:
```Jade
// app/views/stock.jade
.header
	// (...)
.body
	// (...)
	if openingPrice == "N/A"
		.loading Invalid name
	// (...)
```

Questions & Comments
====================
Feel free to contact me for questions, comments and feedback.