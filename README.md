Stock Ticker
===============
![Screenshot](http://markmarijnissen.github.com/stockticker/img/screenshot.png)

View [demo here](http://markmarijnissen.github.com/stockticker), or run the [test suite](http://markmarijnissen.github.com/stockticker/test)

What follows is a short walkthrough on how the app is build.

Stock Ticker is a modern web-application which displays stock prices in real-time.
* Responsive & Mobile-friendly layout
* Add & Remove Stock-items
* Drag & Drop to reorder items
* Persistance using localStorage
* CSS3 animations on stock updates

It is build using the following technology:

* **jQuery** and **[Spine.js](http://www.spinejs.com)**, a MCV framework
* **[LiveScript](http://gkz.github.com/LiveScript/)**, which compiles into JavaScript.
* **[Jade](https://github.com/visionmedia/jade#readme)**, a template engine.
* **[LESS](http://www.lesscss.org)**, which compiles into CSS.
* **[Brunch](http://brunch.io)**, a build tool.

Brunch can also watch your files and run a local server, which means LiveScript, Jade and LESS get continuously compiled, concatenated and minified, and you only have to refresh the browser to view the app.

All these tools run on [Node.js](http://nodejs.org/)

I assume you already have knowledge of the MVC design pattern, HTML, CSS and JavaScript. For a more thorough understanding, I refer you to the documentation: [Spine.js](http://spinejs.com/docs), [Mocha](http://mochajs.org/), [Brunch](http://www.brunch.io), [Jade](https://github.com/visionmedia/jade#readme), [LiveScript](http://gkz.github.com/LiveScript/) and [LESS](http://www.lesscss.org)

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
`@configure` defines the class name and attributes. This is used throughout Spine.js, for example when saving and searching instances in the global Stock collection.

We will use this global Stock collection to keep track of all stock-items. This allows us to save everything for persistence, and to join all stock-items in a single request for the Yahoo Stock server.

The model will be displayed with a stock view:
`app/views/stock.jade`
```jade
.header
	.symbol #{symbol}
	.name(title=name) #{name}
.body
	price = (currentPrice*1).toFixed(2)
	percent = (percentage*1).toFixed(2)
	if currentPrice > 0
		.price #{price}
		if percentage > 0
			.percentage.positive +#{percent}%
		else
			.percentage.negative #{percent}% 
	else
		.loading Loading...
		.percentage
```
As you can see, the template has a little display logic:
* It will display "Loading" when the stock has not retrieved.
* It adds 'positive' or 'negative' styling to the percentage.
* It formats the numbers

Finally, a controller connects the view with the model. Controllers deal with rendering templates and responding to DOM events. They are the 'glue' that keeps the model and view in sync. Spine.js controllers have a DOM element associated with it, and some convenience methods to manipulate it.

Here is how we connect the controller with the view:

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
		# re-render view upon model change
		@model.bind 'change',@render
		# render upon creation
		@render!

	# render the template with the Stock model
	render: ~> @html @template(@model)

module.exports = StockController
```

We also need to connect it with the model. We can just create a model, but that will allow us to create duplicate instances of a single stock. To avoid this, we first check if the model is already available in the global Stock collection.

We add this code to the contructor:
```CoffeeScript
	symbol = attrs.symbol
	# bind to an existing model instance, it it exists
	@model = Stock.findByAttribute 'symbol',symbol
	# otherwise, create a fresh model & save it to global collection
	unless @model?
		@model = new Stock symbol:symbol
		@model = @model.save!
```

Step 2. Testing
---------------
We should test if our app behaves as expected. We use [Mocha](http://mochajs.org/) as testing framework. Test are executed using `brunch test` or by using the browser runner at [localhost:3333/test](http://localhost:3333/test).

`brunch test` is run in Node.js, and calls `test_helpers.coffee` to include necessary libraries, such the 
[chai.js](http://chaijs.com/api/bdd/) **expect** grammar.

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
		expect $(stock.el).find('.loading') .to.be.ok
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

Step 3. The App Controller
--------------------
Our main application is simply a collection of stock-items, so we only need a controller to add and remove stock-items:
```CoffeeScript
StockController = require('controllers/stock')

class AppController extends Spine.Controller
	->
		super ...
		@bind 'change',@render
		[@add symbol for symbol in <[BARC.L LLOY.L STAN.L]>]

	# create a new StockController, and append the element
	add: (symbol,override = no) ~> 
		# only add if symbol is valid and not added before
		if typeof symbol is 'string' and (override or Stock.findByAttribute('symbol',symbol.toUpperCase!) is null)
			stock = new StockController(symbol:symbol)
			$(@el).find '.container' .append stock.el

	# find and destroy the Stock, which destroys the controller, which destroys the element.
	remove: (symbol) -> Stock.findByAttribute('symbol',symbol).destroy()
					
module.exports = AppController
```
To remove the element upon destruction of the Stock model instance, we need to bind the 
destroy event of the model to the release function of the controller.

So we add to the StockController constructor:
```CoffeeScript
	@stock.bind 'destroy',@release
```

Step 4: Styling: Responsive Layout
==================================
With LESS, it is also easy to create a responsive layout. You simply create a mixin that takes the size as argument, and then call this mixin with different sizes in media-queries. Below is a simplified version:

```CSS
// simplified version of "app/styles/stock.less"

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

Step 5: Server Functionality
============================
Stock Prices are fetched from a JSON-API run served by a PHP-script on the server. We can save some requests by combining all stock-prices into a single request.

We use jQuery to perform an AJAX-request:
```CoffeeScript
# app/models/sync.ls

# sync
sync = ->	
	# join all stock symbols from global Stock collection with a ','
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
	if data is "ERROR_NO_ARGUMENTS" then onError data
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

Step 6: Animations
==================
I have created CSS3 animations to flash green or red when the stock-price changes.
We need to update the render function to invoke these animations.

We simply store the price each time we render the stock template, so we can compare on each render
whether a change has occured and we need to invoke an animation:

```CoffeeScript
	# render the template with the Stock model
	render: ~> 
		@html @template(@model)
		# animate a flash when the price changes
		if @previousPrice < @model.currentPrice then 
			@animate 'increase'
		else if @previousPrice > @model.currentPrice
			@animate 'decrease'
		# store 'previous price' to compare with on next render
		@previousPrice = @model.currentPrice
```

The animation function adds and removes the animation-class. This causes gracefull degradation in old browsers: When animations are not supported, the stock-view simply shows a different background for a brief moment. In never browers, removing the animation class ensures we can invoke the animation again on the next change.

```CoffeeScript
	animate: (css) ~>
		$body = @$ '.body'
		$body.addClass css		
		setTimeout (~> $body.removeClass css),1000ms
```

Step 7: Persistence
===================
Adding `@extend(Spine.Model.Local)` to our Stock model saves the instances to localStorage.
By calling `Stock.fetch()` upon construction, we retrieve the instances. This saves us waiting for the stock information to come in.

Step 8: Re-order items with drag & drop
=======================================
By adding jQuery-UI's sortable plugin, it is easy to drag & drop stock-items to a new position. We call `$(...).sortable()` on the container of the Stock-elements.

To remember this order after a reload, we number & save the position of the stock-elements:
```CoffeeScript
	# update & save positions when sorting ends
	savePosition: ~>
		# iterate over stock elements
		$ ".stock" .each (i,el) ->
			# find the stock element based on value of .symbol div
			stock = Stock.findByAttribute('symbol',$ el .find '.symbol' .text!)
			# set & save position
			stock.position = i
			stock.save!
```

When fetching saved data from localStorage, we sort our stock-items on position:
```CoffeeScript
	saved.sort (a,b) -> a.position > b.position
```

Step 9: Adding and removing Stock-items
=======================================
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
	# app/controllers/app.ls
	events:
		'click #add': 'onAddClick'	
		'keyup #add-input': 'onKeyUp'	

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

Step 10. Mobile Debugging
=========================
When running the web-app on Android, persistence did not work correctly. But how do you debug a mobile device? We use [Weinre](http://people.apache.org/~pmuellr/weinre/docs/latest/Home.html) - **WE**b **IN**spector **RE**mote.

```Bash
npm install weinre -g
weinre --boundHost -all-
```
Now connect your android to the same WIFI as your computer, and look up the IP-adress:
```Bash
ifconfig | grep "inet addr"
```
Then we insert this script to `app/assets/index.html`:
```HTML
<script src="http://192.168.2.58:8080/target/target-script-min.js#anonymous"></script>
```

As it turns out, Spine.js' local library had a bug: `JSON.stringify(this)` was used to serialize the Stock collection. However, on Android, it does not implicitly call `this.toJSON()` as on desktop browsers, so we had to explicitly call `toJSON()` to fix the bug. (Pull request send!)


Questions & Comments
====================
Feel free to contact me for questions, comments and feedback.
