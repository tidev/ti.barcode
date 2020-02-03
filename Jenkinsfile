library 'pipeline-library'

def isMaster = env.BRANCH_NAME.equals('master')

buildModule {
	sdkVersion = '9.0.0.v20200203102947'
	iosLabels = 'osx && xcode && appium' // need carthage which we install on appium nodes...
	npmPublish = true // By default it'll do github release on master anyways too
	npmPublishArgs = '--access public --dry-run'
}
