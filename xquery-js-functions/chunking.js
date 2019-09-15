const { registerCustomXPathFunction } = require('fontoxpath');

module.exports = (fileSystemProxy) => {
	registerCustomXPathFunction(
		'generator:create-document-for-node',
		[ 'xs:string', 'node()' ],
		'xs:string',
		(_, fileId, documentNode) => {
			const document = fileSystemProxy.createDocumentForNode(fileId, documentNode);
			return document.id;
		}
	);
};
