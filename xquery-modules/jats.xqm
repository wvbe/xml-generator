module namespace jats = "https://github.com/wvbe/xml-generator/ns/jats";

import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

declare function jats:createRandomSentence () as item()* {
	let $chanceForWordToBeTagged := if (generator:random-boolean(0.75))
		then 0
		else generator:random-number(0.01, 0.1)

	return if ($chanceForWordToBeTagged = 0)
		then generator:random-paragraph()
		else for $word in fn:tokenize(generator:random-paragraph(), '\s+')
			return if (generator:random-number(0, 1) < $chanceForWordToBeTagged)
				then ('',generator:random-content($CM_WRAPPING_INLINES, $word), '')
				else $word

};

declare function jats:createRandomParagraph () as node()* {
	<p>{jats:createRandomSentence()}</p>
};

declare function jats:createRandomSection () as node()* {
	let $amountOfSubSections := fn:floor(generator:random-number(-4, 4)) cast as xs:integer

	return <sec>
		<title>{generator:random-words(3)}</title>
		{
			for $index in 1 to fn:round(generator:random-number(2, 5)) cast as xs:integer
				return generator:random-content($CM_BODY_BLOCKS)
		}
		{ if ($amountOfSubSections < 1)
			then ()
			else for $index in 1 to $amountOfSubSections
				return jats:createRandomSection ()
		}


	</sec>
};

declare function jats:createRandomOrderedList () as node()* {
	<list list-type="{generator:random-controlled-value(array{'order', 'alpha-lower', 'alpha-upper', 'roman-lower', 'roman-upper'})}">
	{
		for $index in 1 to fn:round(generator:random-number(3, 25)) cast as xs:integer
			return <list-item>{jats:createRandomParagraph()}</list-item>
	}
	</list>
};

declare function jats:createRandomUnorderedList () as node()* {
	<list list-type="{generator:random-controlled-value(array{'bullet', 'simple'})}">
	{
		for $index in 1 to fn:round(generator:random-number(2, 9)) cast as xs:integer
			return <list-item>{jats:createRandomParagraph()}</list-item>
	}
	</list>
};

declare variable $CM_BODY_BLOCKS as array(*) := array {
	map {
		'weight': 3,
		'create': function () { jats:createRandomParagraph() }
	},
	map {
		'weight': 0.25,
		'create': function () { jats:createRandomOrderedList() }
	},
	map {
		'weight': 0.25,
		'create': function () { jats:createRandomUnorderedList() }
	}
};

declare variable $CM_WRAPPING_INLINES as array(*) := array {
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<bold>{ $wrapped }</bold>
		}
	},
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<italic>{ $wrapped }</italic>
		}
	},
	map {
		'weight': 0.05,
		'create': function ($wrapped) {
			<underline>{ $wrapped }</underline>
		}
	}
};



declare %public function jats:random-article () as node() {
	let $title := generator:random-phrase()

	return <article
		xmlns:xlink="http://www.w3.org/1999/xlink"
		xmlns:mml="http://www.w3.org/1998/Math/MathML"
		xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		article-type="research-article"
		dtd-version="1.2"
		xml:lang="en"
	>
		<front>
			<journal-meta>
				<journal-id/>
				<issn/>
			</journal-meta>
			<article-meta>
				<title-group>
					<article-title>{generator:random-words(3)}</article-title>
				</title-group>
				<pub-date pub-type="ppub">
					<year/>
				</pub-date>
			</article-meta>
		</front>
		<body>
			{
				for $n in 1 to fn:round(generator:random-number(50, 50)) cast as xs:integer
					return jats:createRandomSection()
			}
		</body>
	</article>
};

