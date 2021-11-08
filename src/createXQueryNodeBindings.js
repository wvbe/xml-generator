const { LoremIpsum } = require('lorem-ipsum');
const { registerCustomXPathFunction } = require('fontoxpath');
const { posix: path } = require('path').posix;
const { v4: uuidv4 } = require('uuid');

const lorem = new LoremIpsum({
	sentencesPerParagraph: {
		max: 8,
		min: 1
	},
	wordsPerSentence: {
		max: 12,
		min: 4
	}
});

module.exports = (addToQueue) => {
	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'create-document-for-node'
		},
		['xs:string', 'node()'],
		'xs:string',
		(_, fileId, documentNode) => addToQueue(fileId, documentNode)
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'create-document-name-for-child'
		},
		['xs:string', 'xs:string'],
		'xs:string',
		(_, parentFileName, childBaseName) =>
			path
				.join(
					parentFileName.substr(
						0,
						parentFileName.length - path.extname(parentFileName).length
					),
					childBaseName
				)
				.replace(/\\/g, '/')
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'log'
		},
		['item()*'],
		'xs:boolean',
		(_, args) => {
			console.group('generator:log');
			args.forEach((value, index) => {
				console.log('#' + index);
				console.dir(value, { depth: 5, colors: true });
			});
			console.groupEnd('generator:log');

			return true;
		}
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'lorem-ipsum'
		},
		['xs:string', 'xs:double'],
		'xs:string',
		(_, type, num) => {
			switch (type) {
				case 'sentence':
					return lorem.generateSentences(num || 1);

				case 'word':
					return lorem.generateWords(num || 1);

				case 'paragraph':
					return lorem.generateParagraphs(num || 1);

				default:
					throw new Error('Unsupported lorem-ipsum type "' + type + '"');
			}
		}
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'random-boolean'
		},
		['xs:double'],
		'xs:boolean',
		(_, probability) => Math.random() <= probability
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'random-number'
		},
		['xs:double', 'xs:double'],
		'xs:double',
		(_, min, max) => Math.random() * (max - min) + min
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'random-identifier'
		},
		[],
		'xs:string',
		(_) => uuidv4()
	);
};
