const { registerCustomXPathFunction } = require('fontoxpath');

module.exports = () => {
	registerCustomXPathFunction('generator:log', ['item()*'], 'xs:boolean', (_, args) => {
		console.group('generator:log');
		args.forEach((value, index) => {
			console.log('#' + index);
			console.dir(value, { depth: 5, colors: true });
		});
		console.groupEnd('generator:log');

		return true;
	});
};
