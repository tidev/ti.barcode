/* global danger, fail, warn, message */

// requires
const junit = require('@seadub/danger-plugin-junit').default;
const dependencies = require('@seadub/danger-plugin-dependencies').default;
const ENV = process.env;

// Add links to artifacts we've stuffed into the ENV.ARTIFACTS variable
async function linkToArtifacts() {
	if (ENV.BUILD_STATUS === 'SUCCESS' || ENV.BUILD_STATUS === 'UNSTABLE') {
		const artifacts = ENV.ARTIFACTS.split(';');
		if (artifacts.length !== 0) {
			const artifactsListing = '- ' + artifacts.map(a => danger.utils.href(`${ENV.BUILD_URL}artifact/${a}`, a)).join('\n- ');
			message(`:floppy_disk: Here are the artifacts produced:\n${artifactsListing}`);
		}
	}
}

async function main() {
	// do a bunch of things in parallel
	// Specifically, anything that collects what labels to add or remove has to be done first before...
	await Promise.all([
		junit({ pathToReport: './TESTS-*.xml' }),
		dependencies({ type: 'npm' }),
		linkToArtifacts(),
	]);
}
main()
	.then(() => process.exit(0))
	.catch(err => {
		fail(err.toString());
		process.exit(1);
	});
