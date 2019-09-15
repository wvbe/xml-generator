module namespace generator = "https://github.com/wvbe/xml-generator/ns";

(:~
	Synchronously queues a new XML document to be written to disk and returns the name of that file
	TODO Clarity and tests on how that file name relates to the cwd and current document
~:)
declare %public function generator:create-document-for-node ($name as xs:string, $node as node()) as xs:string {
	Q{generated_namespace_uri_generator}create-document-for-node($name, $node)
};

(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-phrase () as xs:string {
	Q{generated_namespace_uri_generator}lorem-ipsum('sentence', 1)
};
declare %public function generator:create-document-name-for-child ($parentFileName as xs:string, $childBaseName as xs:string) as xs:string {
	Q{generated_namespace_uri_generator}create-document-name-for-child($parentFileName, $childBaseName)
};

(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-words ($length as xs:double) as xs:string {
	Q{generated_namespace_uri_generator}lorem-ipsum('word', $length)
};

(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-paragraph () as xs:string {
	Q{generated_namespace_uri_generator}lorem-ipsum('paragraph', 1)
};

(:~ Logs a value to the Javascript console ~:)
declare %public function generator:log ($a as item()*) {
	Q{generated_namespace_uri_generator}log($a)
};

(:~ TODO Deprecate in favour of XQuery standard ~:)
declare %public function generator:random-number ($min as xs:double, $max as xs:double) as xs:double {
	Q{generated_namespace_uri_generator}random-number($min, $max)
};
declare %public function generator:random-controlled-value ($options as item()*) as item()* {
	array:get($options, fn:floor(generator:random-number(1, count(array:flatten($options)))) cast as xs:integer)
};

(:~ TODO Deprecate in favour of just XQuery ~:)
declare %public function generator:random-boolean ($probability as xs:double) as xs:boolean {
	Q{generated_namespace_uri_generator}random-boolean($probability)
};


(:~
	Returns the result of a callback chosen semi-randomly, with a "weight" contributing to the probability of it.
	$contentModels is an array of maps, each of which are expected to conform to:
	```
	map {
		'probability': xs:double,
		'create': function () as node()*
	}
	```
 ~:)


declare %public function generator:random-content ($contentModels as array(*)) as node()* {
	generator:random-content($contentModels, ())
};

declare %public function generator:random-content ($contentModels as array(*), $callbackArg as item()*) as node()* {
	(:~ Using the array:flatten'ed copy from now on avoids the atomization problem ~:)
	let $flattenedContentModels := array:flatten($contentModels)

	let $totalWeight := fn:fold-left($flattenedContentModels, 0, function ($total, $item) {
		$item('weight') + $total
	})

	let $randomNumber := generator:random-number(0, $totalWeight)

	let $contentModel := fn:fold-left(
		array:flatten(1 to count($flattenedContentModels)),
		map {
			'lastEndWeight': 0,
			'result': ()
		},

		(:~ Return something if that was already found, or return the first item to include $randomNumber in its range ~:)
		function ($accumulator, $index) {
			if (not(fn:empty($accumulator('result')))) then
				$accumulator
			else
				let $startWeight := $accumulator('lastEndWeight')
				let $endWeight := $startWeight + $flattenedContentModels[$index]('weight')

				return map {
					'lastEndWeight': $endWeight,
					'result': if ($randomNumber <= $endWeight) then
						$flattenedContentModels[$index]
					else ()
				}
		})

	return if (fn:empty($contentModel('result'))) then
		()
	else
		let $callback := $contentModel('result')('create')
		let $callbackArity := fn:function-arity($callback)
		return if ($callbackArity = 0)
			then $callback()
			else $callback($callbackArg)
};
