const { LoremIpsum } = require('lorem-ipsum');
const { registerCustomXPathFunction } = require('fontoxpath');

const lorem = new LoremIpsum({
	sentencesPerParagraph: {
		max: 8,
		min: 1
	},
	wordsPerSentence: {
		max: 16,
		min: 4
	}
});

module.exports = () => {
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
			localName: 'random-number'
		},
		['xs:double', 'xs:double'],
		'xs:double',
		(_, min, max) => {
			return Math.random() * (max - min) + min;
		}
	);

	registerCustomXPathFunction(
		{
			namespaceURI: 'https://github.com/wvbe/xml-generator/ns',
			localName: 'random-boolean'
		},
		['xs:double'],
		'xs:boolean',
		(_, probability) => {
			return Math.random() <= probability;
		}
	);
};
