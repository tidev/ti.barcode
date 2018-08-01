# Change Log
<pre>
v2.0.0  [MOD-2354] 
            - Replaced XZing library with AVFoundation framework.
            - Supported new barcode types -FORMAT_CODE_93,  FORMAT_CODE_39_MOD_43,  FORMAT_PDF_417, FORMAT_AZTEC, FORMAT_INTERLEAVED_2_OF_5
            - Supported new methods -  freezeCapture() and unfreezeCapture()
            - Property 'allowRotation' is removed. By default  it will analyze portrait and landscape image.


v1.9.1  [TIMOB-18092] Fixed linker error when building with TiSDK 3.5.0+

v1.9.0  [MOD-18092] Updating module to support 64-bit.

v1.8.3  [MOD-1265] Building with 2.1.3.GA and open sourcing 
	
v1.8.2  [MOD-1087] Updating attribution
	
v1.8.1	[MOD-603] Fixed useLED to properly report if the LED will be used. Also added a button to the example overlay for toggling it on and off.

v1.8	[MOD-434][MOD-439] Fixed a crash when scanning a VEVENT code, and improved the durability of scanning to not crash the application upon parse errors.
		- BREAKING CHANGE: iOS error event's property "reason" has been renamed to "message" for parity with Android and the documentation.

v1.7	[MOD-377] Fixed regression introduced by Titanium Mobile 1.8.1
		[MOD-403] Fixed crash after parsing an invalid barcode.

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
		- Updated example to use 'var' for module object returned from require.
		[MOD-293] Fixed issue with 'Cancel' button not displaying on capture screen

v1.4    MOD-232 Added ability to disable animation when dismissing camera to eliminate redraw artifacts

v1.3	MOD-114 Resolved problems with scanning Code-128 barcodes by updating to the latest version of ZXing

v1.2    MOD-141 Updated ZXingWidgetController.m to remove references to AVFoundation APIs when compiled to run in the simulator.
        Updated barcode system requirements to state that barcodes are supported in 4.0 and newer
        Exposed "displayedMessage" property to let developers customize the text that is shown to the user

v1.1    Updated to the latest version of ZXing
        Exposed "allowRotation" property to let the module scan in portrait and landscape orientations

v1.0    Initial Release
