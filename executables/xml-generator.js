#!/usr/bin/env node
const path = require('path');
const fs = require('fs');
const log = require('npmlog');

const { Command, Parameter } = require('ask-nicely');

const createXQueryContext = require('../createXQueryContext');
const createXQueryModules = require('../createXQueryModules');

new Command()

	.addParameter(
		new Parameter('main').setResolver(input => {
			if (!input) {
				return [];
			}
			const location = path.resolve(process.cwd(), input);
			if (!fs.existsSync(location)) {
				throw new Error(`Script "${input}" could not be found.${location}`);
			}

			return createXQueryModules(location, true);
		})
	)
	.addParameter(
		new Parameter('destination').setResolver(val => {
			const rootFileName = val || 'generated-xml-' + Date.now() + '.xml';

			if (!path.extname(rootFileName)) {
				throw new Error(
					'The destination file must have an extension, for example "' + val + '.xml"'
				);
			}

			return rootFileName;
		})
	)
	.addOption(
		'no-debug',
		'd',
		'Increase performance by not recording debug information for fontoxpath'
	)
	.setController(req => {
		const { onEvent, evaluate, finish } = createXQueryContext({
			debug: !req.options['no-debug'],
			cwd: process.cwd(),
			modules: req.parameters.main,
			variables: {
				workingDirectory: process.cwd(),
				destination: req.parameters.destination
			}
		});

		onEvent('register-module', mod => {
			const message = [`Register module "${mod.prefix}" (${mod.url})`];
			mod.stubbed && message.push('\tNot found, stubbing');
			mod.dependencies.forEach(dep => message.push('\tDepends on: ' + dep));
			log.info('setup', message.join('\n'));
		});

		onEvent('evaluate:start', () => log.info('eval', `Starting evaluation`));

		onEvent('evaluate:finish', () => log.info('eval', `Finished evaluation`));

		onEvent('write:start', () => log.info('disk', `Starting disk output`));

		onEvent('write:item', queueItem => log.info('disk', `Write "${queueItem.name}"`));

		onEvent('write:finish', () => log.info('disk', `Finished disk output`));

		onEvent('queue', queuedItem => log.info('queue', `Queue new file "${queuedItem.id}"`));

		evaluate();

		finish();
	})
	.execute(process.argv.slice(2))
	.catch(error => {
		log.error('fatal', error.stack || error);
		process.exit(1);
	});
