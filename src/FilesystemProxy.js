const { slimdom } = require('slimdom-sax-parser');
const fs = require('fs-extra');
const path = require('path');

module.exports = class FilesystemProxy {
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

		return {
			id: id,
			name
		}
	}

	executeJobs () {
		this.jobs.forEach(([name, callback]) => {
			console.error(name);
			callback();
		});
	}
}