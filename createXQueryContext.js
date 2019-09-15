const { slimdom } = require('slimdom-sax-parser');
const fs = require('fs-extra');
const path = require('path');
const { evaluateXPath, registerXQueryModule } = require('fontoxpath');

// API layer to queue writing documents to disk
class FilesystemProxy {
	constructor (cwd) {
		this.cwd = cwd;
		this.jobs = [];
	}

	createDocumentForNode (id, node) {
		const xml = slimdom.serializeToWellFormedString(node);
		const name = path.resolve(this.cwd, id);
		this.jobs.push([
			'JOB\tcreate\t' + id,
			() => fs.outputFileSync(name, xml)
		]);

		return { id, name };
	}

	executeJobs () {
		this.jobs.forEach(([description, callback]) => {
			console.error(description);
			callback();
		});
	}
}

module.exports = function createXQueryContext ({
	// The working directory for creating new files
	cwd,

	// A list of XQuery modules as objects:
	//   { prefix: 'mml', url: 'http://...', contents: '(:~ XQuery here ~:)' }
	modules,

	// Track fontoxpath debug information
	debug
}) {
	const fileSystemProxy = new FilesystemProxy (cwd);

	// Register a custom XPath functions that talk to node modules
	// Each of these should also have something registered in generator.xqm
	require('./xquery-js-functions/chunking')(fileSystemProxy);
	require('./xquery-js-functions/random')();
	require('./xquery-js-functions/logging')();

	// Register the XQuery modules to fontoxpath
	const moduleImports = modules.reduce((obj, mod) => {
		console.error(['XQM', mod.prefix, mod.url].join('\t'));
		registerXQueryModule(mod.contents);
		return { ...obj, [mod.prefix]: mod.url };
	}, {});

	return {
		evaluate: function evaluateInXQueryContext(variables, xQuery, document = new slimdom.Document()) {
			return evaluateXPath(xQuery, document, null, variables, null, {
				language: evaluateXPath.XQUERY_3_1_LANGUAGE,
				moduleImports,
				debug
			});
		},
		finish: fileSystemProxy.executeJobs.bind(fileSystemProxy)
	};
};