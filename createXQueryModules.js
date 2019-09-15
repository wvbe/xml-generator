const path = require('path');
const fs = require('fs');

// Matches a namespace prefix and url from the module declaration
const MATCH_MODULE_NS_FROM_STRING = /(?:\n|^)module namespace ([a-z]*) = "(.*)"/m;

const LOCATION_BY_NAMESPACE_URL = {
	'https://github.com/wvbe/xml-generator/ns': path.resolve(
		__dirname,
		'xquery-modules',
		'generator.xqm'
	)
};

function getUnsortedModuleDependencyList(location, asMainModule) {
	const MATCH_IMPORTED_MODULE_NS_FROM_STRING = /(?:\n|^)import module namespace ([a-z]*) = "([^"]*)"(?: at "([^"]*)")?;/gm;

	let modules = [];
	const contents = fs.readFileSync(location, 'utf8');

	const namespaceInfo = MATCH_MODULE_NS_FROM_STRING.exec(contents);
	if (!asMainModule && !namespaceInfo) {
		throw new Error('Could not extract namespace info from XQuery module\n' + location);
	}

	const [_match, prefix, url] = namespaceInfo || [];

	const dependencies = [];
	while ((match = MATCH_IMPORTED_MODULE_NS_FROM_STRING.exec(contents)) !== null) {
		const [_occurrence, prefix, url, importedLocation] = match;
		dependencies.push(url);

		if (importedLocation) {
			modules = modules.concat(
				getUnsortedModuleDependencyList(
					path.resolve(path.dirname(location), importedLocation)
				)
			);
		} else if (LOCATION_BY_NAMESPACE_URL[url]) {
			modules = modules.concat(
				getUnsortedModuleDependencyList(LOCATION_BY_NAMESPACE_URL[url])
			);
		} else {
			modules.push({
				prefix,
				url,
				contents: `module namespace ${prefix} = "${url}";`,
				main: false,
				stubbed: true,
				dependencies: []
			});
		}
	}

	modules.push({
		location,
		prefix,
		url,
		contents,
		dependencies,
		main: !!asMainModule,
		stubbed: false
	});

	return modules.filter((mod, i, all) => all.findIndex(m => m.url === mod.url) === i);
}

module.exports = function createXQueryModules(location) {
	const modulesInRandomOrder = getUnsortedModuleDependencyList(location, true);
	const modulesInDependencyOrder = [];

	let safety = modulesInRandomOrder.length;
	while (modulesInRandomOrder.length) {
		if (--safety < 0) {
			throw new Error(
				`Could not resolve dependencies for ${modulesInRandomOrder.length} modules:\n\t` +
					modulesInRandomOrder.map(m => m.url)
			);
		}
		const nextModuleWithoutUnresolvedDependencies = modulesInRandomOrder.find(mod =>
			mod.dependencies.every(dep => modulesInDependencyOrder.find(m => m.url === dep))
		);
		modulesInRandomOrder.splice(
			modulesInRandomOrder.indexOf(nextModuleWithoutUnresolvedDependencies),
			1
		);
		modulesInDependencyOrder.push(nextModuleWithoutUnresolvedDependencies);
	}

	return modulesInDependencyOrder;
};
