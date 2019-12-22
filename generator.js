#!/usr/bin/env node
const path = require('path');
const fs = require('fs');
const log = require('npmlog');

const { Command, Parameter } = require('ask-nicely');

const createXQueryContext = require('./src/createXQueryContext');
const createXQueryModules = require('./src/createXQueryModules');

new Command()

	.addParameter(
		new Parameter('main').setResolver(input => {
			if (!input) {
				throw new Error('The first parameter must point to your XQuery main module file');
			}

			const location = path.resolve(process.cwd(), input);
			if (!fs.existsSync(location)) {
				throw new Error(`Script "${input}" could not be found.`);
			}

			return location;
		})
	)
	.addParameter(
		new Parameter('destination').setResolver(rootFileName => {
			if (!rootFileName) {
				throw new Error('The second parameter must be the $destination file');
			}

			if (!path.extname(rootFileName)) {
				throw new Error(
					'The destination file must have an extension, for example "' + rootFileName + '.xml"'
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
			modules: createXQueryModules(req.parameters.main),
			variables: {
				workingDirectory: process.cwd(),
				destination: req.parameters.destination
			}
		});

		onEvent('register-module', mod => {
			log.info('setup', `Register module "${mod.prefix}" (${mod.url})`);
			mod.unresolved && log.warn('setup', '\tLibrary module not resolved');
			mod.dependencies.forEach(dep => log.info('setup', '\tDepends on: ' + dep));
		});

		onEvent('evaluate:start', () => log.info('eval', `Starting evaluation`));

		onEvent('evaluate:finish', (result) => log.info('eval', `Finished evaluation`) || log.info('result', result));

		onEvent('write:start', () => log.info('disk', `Starting disk output`));

		onEvent('write:item', queueItem => log.verbose('disk', `Write "${queueItem.name}"`));

		onEvent('write:finish', () => log.info('disk', `Finished disk output`));

		onEvent('queue', queuedItem => log.verbose('queue', `Queue new file "${queuedItem.id}"`));

		evaluate();

		finish();
	})

	.execute(process.argv.slice(2))

	.catch(error => {
		log.error('fatal', error.stack || error);

		process.exitCode = 1;
	});
