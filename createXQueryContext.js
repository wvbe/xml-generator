const slimdom = require('slimdom');
const fs = require('fs-extra');
const path = require('path');
const { evaluateXPath, registerXQueryModule } = require('fontoxpath');
const EventEmitter = require('events');

module.exports = function createXQueryContext({
	variables,

	// The working directory for creating new files
	cwd,

	// A list of XQuery modules as objects:
	//   { prefix: 'mml', url: 'http://...', contents: '(:~ XQuery here ~:)' }
	modules = [],

	// Track fontoxpath debug information
	debug
}) {
	const eventEmitter = new EventEmitter();
	const queue = [];
	function addToQueue(id, node) {
		const queueItem = {
			id,
			name: path.resolve(cwd, id),
			xml: slimdom.serializeToWellFormedString(node).replace(/\s+/g, ' ')
		};
		queue.push(queueItem);
		eventEmitter.emit('queue', queueItem);
		return queueItem;
	}

	// Register a custom XPath functions that talk to node modules
	// Each of these should also have something registered in generator.xqm
	require('./xquery-js-functions/chunking')(addToQueue);
	require('./xquery-js-functions/random')();
	require('./xquery-js-functions/logging')();

	// Register the XQuery modules to fontoxpath
	const mainModule = modules.find(mod => mod.main);
	if (!mainModule) {
		throw new Error('A main XQuery module is required');
	}

	return {
		evaluate: function evaluateInXQueryContext() {
			modules
				.filter(mod => !mod.main)
				// @TODO dependency load order
				// .reverse()
				.reduce((obj, mod) => {
					eventEmitter.emit('register-module', mod);
					registerXQueryModule(mod.contents, { debug });
				}, {});

			eventEmitter.emit('evaluate:start');
			evaluateXPath(mainModule.contents, new slimdom.Document(), null, variables, null, {
				language: evaluateXPath.XQUERY_3_1_LANGUAGE,
				// moduleImports: libraryModules,
				debug
			});
			eventEmitter.emit('evaluate:finish');
		},

		onEvent: eventEmitter.on.bind(eventEmitter),

		finish: () => {
			eventEmitter.emit('write:start');
			queue.forEach(queueItem => {
				eventEmitter.emit('write:item', queueItem);
				fs.outputFileSync(queueItem.name, queueItem.xml);
			});
			eventEmitter.emit('write:finish');
		}
	};
};
