A NodeJS based XQuery tool that generates XML documents. Those documents are dummy data for
testing one software or another (I work for [FontoXML](https://fontoxml.com)).

# Features

-   A bunch of XPath/XQuery functions that let you generate randomized data of various types.
-   The ability to load your own XQuery modules that define even more of those functions.
-   Save the outcome of this stuff to one or more XML files.

The tool contains a configuration for DITA 1.3 content. If no additional parameters are used, these XQuery modules and
that expression is used, and results in a DITA map with approximately 50 topics.

# Usage

Can be used without installing `xml-generator` if you run `npx wvbe/xml-generator` instead.

```sh
# Use all the default settings
xml-generator output.xml --expression "<test foo='bar' />"
```

```sh
# Generate an extremely simple, not so random XML
xml-generator output.xml --expression "<test foo='bar' />"
```

```sh
# Generate one random DITA topic (using the built-in DITA modules)
xml-generator output.dita -x "dita:random-topic()"
```

```sh
# Generate XML based on whatever you have in your own XQuery module
xml-generator output.xml -x "my:custom-function()" --modules my-custom-module.xqm

# See also "Customization"
```

# Customization

Generating random XML is not fun if you can't do it for the schema that you need. For this reason, the `--expression`
flag lets you decide for yourself what the output is gonna be, and the `--modules` option lets you import more XQuery
modules with XPath/XQuery definitions.

For example, a custom XQuery module could contain:

```xquery
module namespace my = "https://my/module/namespace/uri";

import module namespace generator = "https://github.com/wvbe/xml-generator/ns";

declare %public function my:custom-function () as node() {
	<recipe xmlns="http://my/schema/namespace/uri">
		<ingredients>
			{
				for $index in 1 to fn:round(generator:random-number(5, 10)) cast as xs:integer
					return <ingredient>{generator:random-words(1)}</ingredient>
			}
		</ingredients>
		<steps>
			{
				for $index in 1 to fn:round(generator:random-number(2, 5)) cast as xs:integer
					return <step>{generator:random-paragraph()}</step>
			}
		</steps>
	</recipe>
};
```
