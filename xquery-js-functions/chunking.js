const { registerCustomXPathFunction } = require('fontoxpath');
const path = require('path').posix;
module.exports = addToQueue => {
	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'create-document-for-node'
		},
		['xs:string', 'node()'],
		'xs:string',
		(_, fileId, documentNode) => {
			const document = addToQueue(fileId, documentNode);
			return document.id;
		}
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'create-document-name-for-child'
		},
		['xs:string', 'xs:string'],
		'xs:string',
		(_, parentFileName, childBaseName) => {
			return path
				.join(
					parentFileName.substr(
						0,
						parentFileName.length - path.extname(parentFileName).length
					),
					childBaseName
				)
				.replace(/\\/g, '/');
		}
	);
};
