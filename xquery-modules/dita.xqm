module namespace dita = "https://github.com/wvbe/xml-generator/ns/dita";

import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

declare function dita:createRandomSentence () as item()* {
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

declare function dita:createRandomParagraph () as node()* {
	<p>{dita:createRandomSentence()}</p>
};

declare function dita:createRandomOrderedList () as node()* {
	<ol>
	{
		for $index in 1 to fn:round(generator:random-number(3, 25)) cast as xs:integer
			return <li>{dita:createRandomParagraph()}</li>
	}
	</ol>
};

declare function dita:createRandomUnorderedList () as node()* {
	<ul>
	{
		for $index in 1 to fn:round(generator:random-number(2, 9)) cast as xs:integer
			return <li>{dita:createRandomParagraph()}</li>
	}
	</ul>
};

declare function dita:createRandomNote () as node()* {
	<note type="{generator:random-controlled-value(array{'important', 'danger', 'info'})}">
		{dita:createRandomParagraph()}
	</note>
};

declare function dita:createRandomLongQuote () as node()* {
	<lq>
		{dita:createRandomParagraph()}
	</lq>
};

declare variable $CM_BODY_BLOCKS as array(*) := array {
	map {
		'weight': 3,
		'create': function () { dita:createRandomParagraph() }
	},
	map {
		'weight': 1,
		'create': function () { dita:createRandomNote() }
	},
	map {
		'weight': 0.25,
		'create': function () { dita:createRandomOrderedList() }
	},
	map {
		'weight': 0.25,
		'create': function () { dita:createRandomUnorderedList() }
	},
	map {
		'weight': 0.1,
		'create': function () { dita:createRandomLongQuote() }
	}
};

declare variable $CM_WRAPPING_INLINES as array(*) := array {
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<b>{ $wrapped }</b>
		}
	},
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<i>{ $wrapped }</i>
		}
	},
	map {
		'weight': 0.05,
		'create': function ($wrapped) {
			<u>{ $wrapped }</u>
		}
	},
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<xref href="http://dummy" scope="external">{ $wrapped }</xref>
		}
	},
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<codeph>{ $wrapped }</codeph>
		}
	}
};

declare %public function dita:makeTopicrefToNewTopic ($parentFileName, $options, $name) as node() {
	let $topicOptions := $options('topicOptions')

	return if (generator:random-boolean(0.0825))

		then <topichead>
			<topicmeta>
				<navtitle>{generator:random-words(3)}</navtitle>
			</topicmeta>
			{
				for $n in 1 to generator:random-number(2, 5) cast as xs:integer
					return <topicref href="{
						generator:create-document-for-node(
							generator:create-document-name-for-child(
								$parentFileName,
								concat('topic-', $name, '-', $n, '.dita')
							),
							dita:makeTopicNode($topicOptions)
						)
					}" />
			}
		</topichead>

		else <topicref href="{
			generator:create-document-for-node(
				generator:create-document-name-for-child(
					$parentFileName,
					concat('topic-', $name, '.dita')
				),
				dita:makeTopicNode($topicOptions)
			)
		}" />
};

declare %public function dita:makeTopicNode ($options) as node() {
	let $topicOptions := $options('topicOptions'),
		$title := generator:random-phrase()

	return <topic
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:topic.xsd:1.3"
		id="test-topic"
	>
		<title>{$title}</title>
		<body>{
			for $index in 1 to fn:round(generator:random-number(2, 9)) cast as xs:integer
				return generator:random-content($CM_BODY_BLOCKS)
		}
		</body>
	</topic>
};

declare %public function dita:makeMapNode ($parentFileName, $options, $mapDepth) as node() {
	let $mapOptions := $options('mapOptions'),
		$title := generator:random-phrase()

	return <map
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:map.xsd:1.3"
		id="test-map"
	>
		<title>{$title}</title>

		{
			for $n in 1 to fn:round(generator:random-number($mapOptions('minimumTopics'), $mapOptions('maximumTopics'))) cast as xs:integer
				return dita:makeTopicrefToNewTopic ($parentFileName, $options, $n)
		}
	</map>
};

