<?php
/* Simple Stock-Ticker JSON-API

A very simple script which CURLs Yahoo's Stock data and formats it in a JSON response.

A bigger project obviously needs better structure, for example:
- router: 		a router (to map requests to function calls)
- validation: 	central validation methods (i.e. DRY in the function calls)
- database: 	an ORM library for database manipulation
- business logic modules: containing the actual functions that execute the API call.
- error: 		central error messages 
- app: 			An app that ties all of the above together.

This is where MVC frameworks such as CakePHP might save reinventing the wheel -
especially ORM and validation can be quite tiresome to get right.

It would also be wise to cache the results on the server when we have many clients,
as the CURL to Yahoo is one of the bottlenecks in a fast response performance.
   
*/
const ERROR_NO_ARGUMENTS = "ERROR_NO_ARGUMENTS";
const ERROR_INVALID_NAME = "ERROR_INVALID_NAME";

run();

// runs everything
function run() {

	$symbols = IsSet($_GET['q'])? $_GET['q']: null;

	if($symbols == null) {
		respond(ERROR_NO_ARGUMENTS);
	} else {
		respond(getStocks($symbols));
	}
}

// curls YAHOO and converts CSV to JSON
function getStocks($symbols) {
	$csv = curl($symbols);
	$lines = explode("\r\n",$csv);
	
	//delete last empty line
	unset($lines[count($lines)-1]);
	
	// iterate over lines
	foreach($lines as $line) {
		//extract values
		list($symbol,$name,$currentPrice,$openingPrice) = explode(',',$line);
		// trim quotes
		$symbol = trim($symbol,'"');
		$name = trim($name,'"');
		if($openingPrice != "N/A")
			$openingPrice = $openingPrice * 1.00;
		$currentPrice = $currentPrice * 1.00;
		if(IsSet($_GET['randomize']))
			$currentPrice += rand(0,10) - 5;
		$percentage = $openingPrice > 0 
						? (($currentPrice / $openingPrice) - 1) * 100.0
						: 0.0;
		
		$data[$symbol] = array(
				'name' => $name,
				'symbol' => $symbol,
				'openingPrice' => $openingPrice,
				'currentPrice' => $currentPrice,
				'percentage' => $percentage
			);
		
	}
	return $data;
}

// curls YAHOO server and returns result as string
function curl($stocks) {
	$ch = curl_init(); 
	curl_setopt($ch, CURLOPT_URL, "download.finance.yahoo.com/d/quotes.csv?s=$stocks&f=snl1o"); 
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1); 
	$output = curl_exec($ch); 
    curl_close($ch);
    return $output;
}

// encodes data as JSON and writes the response
function respond($data) {
	header('content-type: application/json; charset=utf-8');
	$json = json_encode($data);
	echo isset($_GET['callback'])
    	? "{$_GET['callback']}($json)"
    	: $json;
    exit();
}	


?>