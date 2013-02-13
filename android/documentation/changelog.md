# Change Log
<pre>
v2.3.4  [MOD-1265] Open sourcing
	
v2.3.3  [MOD-1087][MOD-1104] Updating attribution and building with 2.1.3.GA to support x86 devices
	
v2.3.2  [MOD-791] Fixed collision on app_name in strings.xml

v2.3.1  [MOD-744] Re-fixed issue with strings.xml collision

v2.3.0	[MOD-564] Upgraded to ZXing v2.0
		- Android now has a "allowInstructions" property on the module. See the documentation to find out more.

v2.2.1	[MOD-643] Fixed a crash when scanning GEO QR Codes, and split the possible ?q= in to a "query" variable.

v2.2	[MOD-434][MOD-439] Fixed a crash when scanning a VEVENT code, and improved the durability of scanning to not crash the application upon parse errors.

v2.1	[MOD-230] Fixed collision of strings.xml by namespacing this module's strings.xml files.
		[MOD-352] Fixed crash when passing no arguments to the "capture" method.
		[MOD-352] Fixed the "displayedMessage" and "allowRotation" properties that were broken by the 2.0 release.

v2.0	Upgraded to module api version 2 for 1.8.0.1
		[MOD-303] Fixed anyDensity="false" misplacement of barcode results.
		
v1.7	Backported [MOD-230] for 1.7.x support.
		Backported [MOD-303] for 1.7.x support.

v1.6	[MOD-304] Added "acceptedFormats" and relevant constants. Check out the documentation and example to find out more.
		[MOD-202] Added "parse" method for finding barcodes in blobs. See documentation and example for more information.
		[MOD-250] Added "useLED" property to the module for lighting the LED during scanning, if available.

v1.5	[MOD-241][MOD-256] Added a "useFrontCamera" property to the module to control which camera is used.
		[MOD-254][MOD-253] "capture" now accepts the "keepOpen" boolean key. Check out the example and documentation to find out more.
		[MOD-90] "capture" now accepts several new keys: overlay, which takes a view; and showRectangle, which takes a boolean.
		[MOD-223] Established parity between iOS and Android Barcode modules.
		- BREAKING CHANGE: iOS now uses event listeners instead of callbacks! Use Ti.Barcode.addEventListener('success', ...) instead of capture({ success: ...})!
		- BREAKING CHANGE: Android's contentType property is now an integer, instead of a string! Check out the example and documentation to find out more.
		- BREAKING CHANGE: All automatically parsed "data" keys will now be lower case. This ensures consistency across the API and ease of access. 
		- BREAKING CHANGE: Android now properly fires the "cancel" event, as documented. It was firing the "canceled" event.
		- Updated examples to be identical; only difference is iOS's example utilizes the allowRotation property.
		- Added support for processing "WIFI" QR Codes.
		- Android now supports the "data" property, offering up a easy to use dictionary of the properties from the scanned barcode.
		- Android now has a "allowMenu" property on the module. See the documentation to find out more.
		[MOD-295] Resolved crash after capture when no overlay is specified


v1.3    [MOD-231] Enable barcode menu intents (share, history, etc.)
        [MOD-233] Added ability to disable animation during activity transition to camera

v1.2    [MOD-217] Automatically select the current application as the scanning source

v1.1    [MOD-149] Fixed to use activity of invocation rather than default activity

v1.0    Initial Release
