const { registerCustomXPathFunction } = require('fontoxpath');

module.exports = () => {
	registerCustomXPathFunction('generator:log', ['item()*'], 'xs:boolean', (_, args) => {
		args.forEach((value, index) => {
			console.log('Value #' + index);
			console.dir(value, { depth: 5, colors: true });
		});

		return true;
	});
};
