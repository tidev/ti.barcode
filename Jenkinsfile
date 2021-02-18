library 'pipeline-library'

def isMaster = env.BRANCH_NAME.equals('master')

buildModule {
	sdkVersion = '9.3.2.GA'
	iosLabels = 'osx && xcode-12 && appium' // need carthage which we install on appium nodes...
	npmPublish = isMaster // By default it'll do github release on master anyways too
	npmPublishArgs = '--access public'
}
