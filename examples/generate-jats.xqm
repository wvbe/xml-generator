import module namespace jats = "https://github.com/wvbe/xml-generator/ns/jats";
import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

declare variable $destination external;

generator:create-document-for-node(
	$destination,
	jats:random-article ()
)