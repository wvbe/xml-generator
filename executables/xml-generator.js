#!/usr/bin/env node
const path = require('path');
const { readFileSync } = require('fs');
const { Command, Parameter } = require('ask-nicely');

const createXQueryContext = require('../createXQueryContext');

// Matches a namespace prefix and url from the module declaration
const MATCH_MODULE_NS_FROM_STRING = /(?:\n|^)module namespace ([a-z]*) = "(.*)"/m;

// Load these XQuery modules
const AUTOLOADING_XQUERY_MODULES = [
	// Keep "generator" in at all times, it provides the bridge from XQ to NodeJS
	path.join(__dirname, '..', 'xquery-modules', 'generator.xqm'),

	path.join(__dirname, '..', 'xquery-modules', 'dita.xqm')
]

// Reads (XQuery module) files from disk and extracts the namespace information required to register
// with fontoxpath.
function getXqueryModuleSpecification (location) {
	const contents = readFileSync(location, 'utf8');
	const namespaceInfo = MATCH_MODULE_NS_FROM_STRING.exec(contents);

	if (!namespaceInfo) {
		throw new Error('Could not extract namespace info from XQuery module\n' + location);
	}
	const [_match, prefix, url]  = namespaceInfo;
	return { prefix, url, contents };
};

new Command()
	.addOption('no-debug', 'd', 'Increase performance by not recording debug information for fontoxpath')
	.addParameter(
		new Parameter('destination').setResolver(val => {
			const rootFileName = val || 'generated-xml-' + Date.now() + '.ditamap';

			if (!path.extname(rootFileName)) {
				throw new Error('The destination file must have an extension, for example "' + val + '.xml"')
			}

			return rootFileName;
		})
	)
	.setController(req => {
		const options = {
			mapOptions: {
				minimumTopics: 500,
				maximumTopics: 500,
				minimumMaps: 0,
				maximumMaps: 0,
				maximumMapDepth: 0
			},
			topicOptions: {}
		};
		console.error('--- Setup phase');
		console.error('CWD\t' + process.cwd());
		console.error('FNAME\t' + req.parameters.destination);
		console.error('OPTS\t' + JSON.stringify(options, null, '  ').replace(/"/g, ''));

		console.error('--- Loading XQuery modules');
		const { evaluate, finish } = createXQueryContext({
			debug: !req.options['no-debug'],
			cwd: process.cwd(),
			modules: AUTOLOADING_XQUERY_MODULES.map(getXqueryModuleSpecification)
		});

		console.error('--- Evaluation phase');
		evaluate(
			{ options, outputFileName: req.parameters.destination },
			`
			generator:create-document-for-node(
				$outputFileName,
				dita:makeMapNode ($outputFileName, $options, 0)
			)
			`
		);

		console.error('--- Write phase');
		finish();

		console.error('--- Done');
	})
	.execute(process.argv.slice(2))
	.catch(error => {
		console.error('');
		console.error('-- A fatal error occurred:');
		console.error(error.stack);
		console.error('');
		console.error('Killing the process with fire')
		process.exit(1);
	});
