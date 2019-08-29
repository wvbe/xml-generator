const { slimdom } = require('slimdom-sax-parser');
const { evaluateXPath, registerXQueryModule } = require('fontoxpath');

module.exports = (modules = []) => {
	modules.forEach(mod => registerXQueryModule(mod.contents));

	const moduleImports = modules.reduce((obj, mod) => {
		console.error(['XQM', mod.prefix, mod.url].join('\t'));
		return { ...obj, [mod.prefix]: mod.url };
	}, {});

	/**
	 * A very simple way to create complex new elements
	 *
	 * For example:
	 *   createElementUsingXQuery({ foo: 'bar'}, '<nerf>{$foo}</nerf>');
	 *
	 * Gives:
	 *   <nerf>bar</nerf>
	 */
	return function evaluateXQuery(variables, xQuery, document = new slimdom.Document()) {
		return evaluateXPath(xQuery, document, null, variables, null, {
			debug: true,
			language: evaluateXPath.XQUERY_3_1_LANGUAGE,
			moduleImports: moduleImports
		});
	};
};
