'use strict';
const fs = require('fs-extra');
const path = require('path');

function projectManagerHook(projectManager) {
	projectManager.once('prepared', function () {
		// Copy our test resources into the project!
		const src = path.join(__dirname, 'Resources/images');
		const dest = path.join(this.karmaRunnerProjectPath, 'Resources/images');
		console.log(`Copying ${src} to ${dest}`);
		fs.copySync(src, dest);

		// Trun off app thinning so images don't get shoved in asset catalog
		const tiapp = path.join(this.karmaRunnerProjectPath, 'tiapp.xml');
		const contents = fs.readFileSync(tiapp, 'utf8');
		fs.writeFileSync(tiapp, contents.replace('</ios>', `<use-app-thinning>false</use-app-thinning>
</ios>`), 'utf8');
	});
}
projectManagerHook.$inject = [ 'projectManager' ];

module.exports = config => {
	config.set({
		basePath: '../..',
		frameworks: [ 'jasmine', 'projectManagerHook' ],
		files: [
			'test/unit/specs/**/*spec.js'
		],
		reporters: [ 'mocha', 'junit' ],
		plugins: [
			'karma-*',
			{
				'framework:projectManagerHook': [ 'factory', projectManagerHook ]
			}
		],
		titanium: {
			sdkVersion: config.sdkVersion || '9.3.2.GA'
		},
		customLaunchers: {
			android: {
				base: 'Titanium',
				browserName: 'Android AVD',
				displayName: 'android',
				platform: 'android'
			},
			ios: {
				base: 'Titanium',
				browserName: 'iOS Emulator',
				displayName: 'ios',
				platform: 'ios'
			}
		},
		browsers: [ 'android', 'ios' ],
		client: {
			jasmine: {
				random: false
			}
		},
		singleRun: true,
		retryLimit: 0,
		concurrency: 1,
		browserNoActivityTimeout: 120000,
		captureTimeout: 1200000,
		logLevel: config.LOG_DEBUG
	});
};
