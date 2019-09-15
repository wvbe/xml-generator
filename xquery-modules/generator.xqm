module namespace generator = "https://github.com/wvbe/xml-generator/ns";

import module namespace array = "http://www.w3.org/2005/xpath-functions/array";

(:~
	Synchronously queues a new XML document to be written to disk and returns the name of that file
	TODO Clarity and tests on how that file name relates to the cwd and current document
~:)
declare %public function generator:create-document-for-node ($name as xs:string, $node as node()) as xs:string external;

(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-phrase () as xs:string {
	generator:lorem-ipsum('sentence', 1)
};


(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-words ($length as xs:double) as xs:string {
	generator:lorem-ipsum('word', $length)
};

(:~ Calls the `lorem-ipsum` npm library for randomly generated text ~:)
declare %public function generator:random-paragraph () as xs:string {
	generator:lorem-ipsum('paragraph', 1)
};


declare %public function generator:random-controlled-value ($options as item()*) as item()* {
	array:get($options, fn:floor(generator:random-number(1, count(array:flatten($options)))) cast as xs:integer)
};

(:~ This is a potentially expensive function as it repeats generator:random-content for every word in a string ~:)
declare %public function generator:random-mixed-content ($sentence as xs:string, $contentModels as array(*)) as item()* {
	for $word in fn:tokenize($sentence, '\s+')
		return ('', generator:random-content($contentModels, $word), '')
};

declare %public function generator:random-content ($contentModels as array(*)) as item()* {
	generator:random-content($contentModels, ())
};

declare %public function generator:random-content ($contentModels as array(*), $callbackArg as item()*) as item()* {
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
