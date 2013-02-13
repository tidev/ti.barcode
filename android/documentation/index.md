# Ti.Barcode Module

## Description
Lets you process 1D/2D barcodes.

## Getting Started

View the [Using Titanium Modules](http://docs.appcelerator.com/titanium/latest/#!/guide/Using_Titanium_Modules) document for instructions on getting
started with using this module in your application.

## Warning when Updating to Barcode v1.5
With the 1.5 update to the Barcode Module, several breaking changes have been made. These changes were made to bring
the iOS and Android modules in to full parity. When upgrading to 1.5, you will need to consider the following:

- BREAKING CHANGE: iOS now uses event listeners instead of callbacks! Use Ti.Barcode.addEventListener('success', ...) instead of capture({ success: ...})!
- BREAKING CHANGE: Android's contentType property is now an integer, instead of a string! Check out the example and documentation to find out more.
- BREAKING CHANGE: All automatically parsed "data" keys will now be lower case. This ensures consistency across the API and ease of access. 
- BREAKING CHANGE: Android now properly fires the "cancel" event, as documented. It was firing the "canceled" event.
- Ensure that you assign the module object that is returned from "require('ti.barcode')" to a variable or your event listeners may not receive the barcode events

## Accessing the Ti.Barcode Module
To access this module from JavaScript, you would do the following:

<pre>var Barcode = require('ti.barcode');</pre>

## Functions

### capture([args])
Brings up the camera and begins the capture sequence for processing a barcode. Takes one optional argument, a dictionary
containing any of the following properties:

* animate[boolean]: Indicates if the device should animate between the current activity and the camera activity when the current activity is in a different orientation than the camera. Default is true.
* showCancel[boolean]: Whether or not to include the default cancel button. Defaults to true.
* showRectangle[boolean]: Whether or not to include the default rectangle around the scanning area. Defaults to true.
* overlay[view]: The view to lay on top of the camera activity.
* keepOpen[boolean]: Whether or not to keep the barcode scanner open after a barcode is recognized. Defaults to false. When set to true, "success" will fire once every time a barcode is recognized, up to two times per second. As such, it can fire multiple times for a single barcode!
* acceptedFormats[int[]]: An optional array of int constants detailing which barcode formats are accepted. Defaults to all formats. Check out the "Barcode Format Constants" section below to see the available int constants. 

### parse([args])
Parses a blob image for barcodes. Takes one required argument, a dictionary containing any of the following properties:

* image[blob]: The image blob to parse for a barcode.
* acceptedFormats[int[]]: An optional array of int constants detailing which barcode formats are accepted. Defaults to all formats. Check out the "Barcode Format Constants" section below to see the available int constants. 

### cancel()
Cancels and closes the currently open capture window.

## Events
Use Ti.Barcode.addEventListener() to process the following events that are sent from the module:

### success
Sent upon a successful barcode scan. The event object contains the following fields:

* format[string, Android only] : The format of the barcode 
* result[string] : The raw contents of the barcode 
* code[string, Android only] : The activity result code from the scanning activity. Use the result constants defined in the [Ti.Android][] namespace 
* contentType[int] : The type of barcode content. Use the constants defined in this module to determine which.
* data[object]: The parsed fields associated with the contentType.

### error
Sent when an error occurs. The event object contains the following fields:

* message[string] : The error message 
* code[string] : The activity result code from the scanning activity. Use the result constants defined in the [Ti.Android][] namespace 

### cancel
Sent when the scanning process is canceled. The event object contains the following fields:

* message[string] : The error message 
* code[string] : The activity result code from the scanning activity. Use the result constants defined in the [Ti.Android][] namespace 

## Properties

### allowRotation[boolean, defaults to false, iOS only]
Value that indicates if the barcode capture should analyze captured images in either portrait or landscape device
orientation. (Warning: Analyzing both the captured image and the rotated version(s) of the image will increase the
processing time of the capture.)

* true: Captured images will be analyzed in both portrait and landscape orientation.
* false [default]: Captured images will be analyzed using only the current device orientation.

### allowMenu[boolean, defaults to true, Android only]
Whether or not to allow the built-in ZXing menu to display.

### allowInstructions[boolean, defaults to true, Android only]
Whether or not to display helpful instructions or a changelog when the app is updated.

### displayedMessage[string]
Controls the message that is displayed to the end user when they are capturing a barcode.
                                                                                         
### useFrontCamera[boolean, defaults to false]
Controls whether or not the front camera on the device will be used to capture barcodes. On Android, this requires API
level 9 (Android OS 2.3) or higher. If no front camera is available, this will gracefully fall back to utilize whatever
camera is available.

### useLED[boolean, defaults to false]
Whether or not to use the LED when scanning barcodes (also known as the flashlight, torch, or some derivation thereof).

## Barcode Result Type Constants

### URL[int]
Value representing URL content

### SMS[int]
Value representing SMS content

### TELEPHONE[int]
Value representing telephone number content

### TEXT[int]
Value representing text content

### CALENDAR[int]
Value representing date content

### GEOLOCATION[int]
Value representing geolocation content

### EMAIL[int]
Value representing an email address

### CONTACT[int]
Value representing contact information (vcard or mecard)

### BOOKMARK[int]
Value representing bookmark content

### WIFI[int]
Value representing wifi connection settings

## Barcode Format Constants

### FORMAT_NONE[int]
### FORMAT_QR_CODE[int]
### FORMAT_DATA_MATRIX[int]
### FORMAT_UPC_E[int]
### FORMAT_UPC_A[int]
### FORMAT_EAN_8[int]
### FORMAT_EAN_13[int]
### FORMAT_CODE_128[int]
### FORMAT_CODE_39[int]
### FORMAT_ITF[int]

## Usage
See example.

## Author
Clint Tredway & Dawson Toth

## Module History

View the [change log](changelog.html) for this module.

## Feedback and Support
Please direct all questions, feedback, and concerns to [info@appcelerator.com](mailto:info@appcelerator.com?subject=Android%20Barcode%20Module).

## License
Copyright(c) 2010-2013 by Appcelerator, Inc. All Rights Reserved. Please see the LICENSE file included in the distribution for further details.

[Ti.Android]: http://developer.appcelerator.com/apidoc/mobile/latest/Titanium.Android-module