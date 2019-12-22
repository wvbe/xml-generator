import module namespace dita = "https://github.com/wvbe/xml-generator/ns/dita";
import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

declare variable $destination external;

generator:create-document-for-node(
	$destination,
	dita:random-map ($destination, map {
		'minimumTopics': 50,
		'maximumTopics': 50
	})
)