library 'pipeline-library'

def isMaster = env.BRANCH_NAME.equals('master')

buildModule {
	// FIXME: Use 8.2.1.GA when it's released
	// sdkVersion = '8.2.1.GA'
	sdkVersion = '8.2.1.v20191001063013' // USe 8_2_X branch build with TiBase.h header fix. 8.2.1GA+ should eventually work fine.
	iosLabels = 'osx && xcode && appium' // need carthage which we install on appium nodes...
	npmPublish = true // By default it'll do github release on master anyways too
	npmPublishArgs = '--access public --dry-run'
}
