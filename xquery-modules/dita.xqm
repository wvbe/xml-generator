module namespace dita = "https://github.com/wvbe/xml-generator/ns/dita";

import module namespace generator = "https://github.com/wvbe/xml-generator/ns" at "./generator.xqm";

declare variable $skeetbrrrp external;

declare variable $CM_LIST_ITEMS_MIN := 3;
declare variable $CM_LIST_ITEMS_MAX := 9;
declare variable $CM_TOPICHEAD_ITEMS_MIN := 2;
declare variable $CM_TOPICHEAD_ITEMS_MAX := 5;
declare variable $CM_BODY_BLOCKS_MIN := 2;
declare variable $CM_BODY_BLOCKS_MAX := 5;
declare variable $CM_BODY_BLOCKS := array {
	map {
		'weight': 3,
		'create': function () { dita:random-p() }
	},
	map {
		'weight': 1,
		'create': function () {
			(:~ If @type is set to "other", @othertype is always set to something lorem ~:)
			let $noteType := generator:random-controlled-value(array {
				'attention', 'caution', 'danger', 'fastpath', 'important',
				'note', 'remember', 'restriction', 'tip',

				'other'
			})

			return <note type="{$noteType}">
				{
					if ($noteType = 'other')
						then (attribute othertype {generator:random-words(1)})
						else ()
				}
				{dita:random-p()}
			</note>
		}
	},
	map {
		'weight': 0.1,
		'create': function () {
			let $columnTotal := generator:random-number(2, 12) cast as xs:integer
			let $rowTotal := generator:random-number(4, 30) cast as xs:integer


			let $noteType := generator:random-controlled-value(array {
				'attention', 'caution', 'danger', 'fastpath', 'important',
				'note', 'remember', 'restriction', 'tip',

				'other'
			})

			return <table>
				<tgroup cols="{$columnTotal}">
					<thead>
						<row>{
							for $index in 1 to $columnTotal
								return <entry>
									<p>{generator:random-words(generator:random-number(1, 3) cast as xs:integer)}</p>
								</entry>
						}</row>
					</thead>
					<tbody>
						{
							for $index in 1 to $rowTotal
								return <row>{
									for $index in 1 to $columnTotal
										return <entry>
											<p>{generator:random-words(generator:random-number(1, 5) cast as xs:integer)}</p>
										</entry>
								}</row>
						}
					</tbody>
				</tgroup>
			</table>
		}
	},
	map {
		'weight': 0.25,
		'create': function () {
			<ol>
			{
				for $index in 1 to fn:round(generator:random-number($CM_LIST_ITEMS_MIN, $CM_LIST_ITEMS_MAX)) cast as xs:integer
					return <li>{dita:random-p()}</li>
			}
			</ol>
		}
	},
	map {
		'weight': 0.25,
		'create': function () {
			<ul>
			{
				for $index in 1 to fn:round(generator:random-number($CM_LIST_ITEMS_MIN, $CM_LIST_ITEMS_MAX)) cast as xs:integer
					return <li>{dita:random-p()}</li>
			}
			</ul>
		}
	},
	map {
		'weight': 0.1,
		'create': function () {
			<lq>
				{dita:random-p()}
				{ if (generator:random-boolean(0.2)) then <longquoteref href="http://dummy" scope="external" /> else ()}
			</lq>
		}
	}
};

declare variable $CM_WRAPPING_INLINES as array(*) := array {
	map {
		'weight': 250,
		'create': function ($wrapped) {
			$wrapped
		}
	},
	map {
		'weight': 1,
		'create': function ($wrapped) {
			<b>{ $wrapped }</b>
		}
	},
	map {
		'weight': 1,
		'create': function ($wrapped) {
			<i>{ $wrapped }</i>
		}
	},
	map {
		'weight': 0.1,
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
	},
	map {
		'weight': 0.5,
		'create': function ($wrapped) {
			<keyword>{ $wrapped }</keyword>
		}
	}
};

declare variable $CM_TOPICS as array(*) := array {
	map {
		'weight': 10,
		'create': function ($parentContext) {
			<topicref href="{
				generator:create-document-for-node(
					generator:create-document-name-for-child(
						$parentContext('parentFileName'),
						concat('topic-', $parentContext('nthChild'), '.dita')
					),
					dita:random-topic()
			)}" />
		}
	},
	map {
		'weight': 2,
		'create': function ($parentContext) {
			<topicref href="{
				generator:create-document-for-node(
					generator:create-document-name-for-child(
						$parentContext('parentFileName'),
						concat('task-', $parentContext('nthChild'), '.dita')
					),
					dita:random-task()
			)}" />
		}
	},
	map {
		'weight': 0.5,
		'create': function ($parentContext) {
			<topicref href="{
				generator:create-document-for-node(
					generator:create-document-name-for-child(
						$parentContext('parentFileName'),
						concat('glossgroup-', $parentContext('nthChild'), '.dita')
					),
					dita:random-glossgroup())
			}" />
		}
	}
};

(:~ This is an expensive function ~:)
declare function dita:random-mixed-content () as item()* {
	if (generator:random-boolean(0.75))
		then generator:random-paragraph()
		else generator:random-mixed-content(generator:random-paragraph(), $CM_WRAPPING_INLINES)

};

declare %public function dita:random-p () as node()* {
	<p>{dita:random-mixed-content()}</p>
};

declare %public function dita:random-topic () as node() {
	let $title := generator:random-phrase()

	return <topic
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:topic.xsd:1.3"
		id="test-topic"
	>
		<title>{$title}</title>
		<body>{
			for $index in 1 to fn:round(generator:random-number($CM_BODY_BLOCKS_MIN, $CM_BODY_BLOCKS_MAX)) cast as xs:integer
				return generator:random-content($CM_BODY_BLOCKS)
		}
		</body>
	</topic>
};

declare %public function dita:random-task () as node() {
	let $title := generator:random-phrase()

	return <task
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:generalTask.xsd:1.3"
		id="test-task"
	>
		<title>{$title}</title>
		<taskbody>
			<steps>{
				for $index in 1 to fn:round(generator:random-number($CM_BODY_BLOCKS_MIN, $CM_BODY_BLOCKS_MAX)) cast as xs:integer
					return <step>
						<cmd>{dita:random-mixed-content()}</cmd>
					</step>
			}
			</steps>
		</taskbody>
	</task>
};

declare %public function dita:random-glossgroup () as node() {
	let $title := generator:random-phrase()

	return <glossgroup
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:glossgroup.xsd:1.3"
		id="test-glossgroup"
	>
		<title>{$title}</title>
		{
			for $index in 1 to fn:round(generator:random-number($CM_BODY_BLOCKS_MIN, $CM_BODY_BLOCKS_MAX)) cast as xs:integer
				return <glossentry>
					<glossterm>{
						generator:random-words(generator:random-number(1, 3) cast as xs:integer)
					}</glossterm>
					<glossdef>{
						for $index in 1 to fn:round(generator:random-number(1, 2)) cast as xs:integer
							return generator:random-content($CM_BODY_BLOCKS)
					}</glossdef>
				</glossentry>
		}
	</glossgroup>
};

declare %public function dita:random-map ($destination, $options) as node() {
	dita:random-map($destination, $options, 0)
};

declare %public function dita:random-map ($destination, $options, $mapDepth) as node() {
	let $title := generator:random-phrase()

	return <map
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xsi:noNamespaceSchemaLocation="urn:fontoxml:names:tc:dita:xsd:map.xsd:1.3"
		id="test-map"
	>
		<title>{$title}</title>

		{
			for $n in 1 to fn:round(generator:random-number($options('minimumTopics'), $options('maximumTopics'))) cast as xs:integer
				return dita:makeTopicrefToNewTopic ($destination, $options, $n)
		}
	</map>
};

declare %private function dita:makeTopicrefToNewTopic ($parentFileName, $options, $name) as node() {
	if (generator:random-boolean(0.0825))
		then <topichead>
			<topicmeta>
				<navtitle>{generator:random-words(3)}</navtitle>
			</topicmeta>
			{
				for $n in 1 to generator:random-number($CM_TOPICHEAD_ITEMS_MIN, $CM_TOPICHEAD_ITEMS_MAX) cast as xs:integer
					return generator:random-content($CM_TOPICS, map { 'parentFileName': $parentFileName, 'nthChild': concat($name, '-', $n) })
			}
		</topichead>

		else generator:random-content($CM_TOPICS, map { 'parentFileName': $parentFileName, 'nthChild': $name })
};
