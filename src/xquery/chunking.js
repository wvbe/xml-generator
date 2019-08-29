const { registerCustomXPathFunction } = require('fontoxpath');

module.exports = (fs) => {
	registerCustomXPathFunction(
		'generator:create-document-for-node',
		[ 'xs:string', 'node()' ],
		'xs:string',
		(_, fileId, documentNode) => {
			const document = fs.createDocumentForNode(fileId, documentNode);
			return document.id;
		}
	);
};
