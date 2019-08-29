#!/usr/bin/env node
const path = require('path');
const fs = require('fs');
const { Command, Parameter } = require('ask-nicely');

const createXQueryContext = require('../src/xquery');
new Command()
	.addParameter(
		new Parameter('destination').setResolver(val =>
			path.resolve(process.cwd(), val || 'generated-xml')
		)
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
		console.error('DEST\t' + req.parameters.destination);
		console.error('OPTS\t' + JSON.stringify(options, null, '  ').replace(/"/g, ''));
		const { evaluate, finish } = createXQueryContext({
			cwd: req.parameters.destination,

			// TODO This url & prefix data should come from the imported files
			modules: [
				{
					url: 'https://github.com/wvbe/xml-generator/ns',
					prefix: 'generator',
					contents: fs.readFileSync(path.join(__dirname, 'generator.xqm'), 'utf8')
				},
				{
					url: 'https://github.com/wvbe/xml-generator/ns/dita',
					prefix: 'dita',
					contents: fs.readFileSync(path.join(__dirname, 'dita.xqm'), 'utf8')
				}
			]
		});

		console.error('--- Evaluation phase');
		evaluate(
			{ options },
			`
			generator:create-document-for-node(
				'map.ditamap',
				dita:makeMapNode ($options, 0)
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
