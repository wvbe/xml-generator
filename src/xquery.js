const FilesystemProxy = require('./FilesystemProxy');

module.exports = function createXQueryContext (options) {
	const fs = new FilesystemProxy (options.cwd);
	require('./xquery/chunking')(fs);
	require('./xquery/random')();
	require('./xquery/logging')();
	return {
		evaluate: require('./xquery/evaluate')(options.modules),
		finish: fs.executeJobs.bind(fs)
	}
}