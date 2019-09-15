import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

import module namespace dita = "https://github.com/wvbe/xml-generator/ns/dita" at "../xquery-modules/dita.xqm";

generator:create-document-for-node(
	$destination,
	dita:random-topic()
)