# Ti.Barcode Module

## Description
Lets you process 1D/2D barcodes.

## System Requirements

- [x] Titanium SDK 5.5.1+
- [x] Camera Permissions set in your tiapp.xml:
```xml
    <ios>
        <plist>
            <dict>
                <key>NSCameraUsageDescription</key>
                <string>We need permission to access your device camera.</string>
            </dict>
        </plist>
    </ios>
```

## Getting Started

View the [Using Titanium Modules](http://docs.appcelerator.com/titanium/latest/#!/guide/Using_Titanium_Modules) document for instructions on getting
started with using this module in your application.

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

### freezeCapture()
Freeze capture keeping the last frame on camera view. This is supported in iOS only.

### unfreezeCapture()
Unfreeze a frozen capture. This is supported in iOS only.

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
* code[string, Android only] : The activity result code from the scanning activity. Use the result constants defined in the [Ti.Android][] namespace 

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
### FORMAT_CODE_93[int, iOS only]
### FORMAT_CODE_39_MOD_43[int, iOS only ]
### FORMAT_PDF_417[int, iOS only ]
### FORMAT_AZTEC[int, iOS only ]
### FORMAT_INTERLEAVED_2_OF_5[int, iOS only ]

## Usage
See `example/app.js` for details!

## Author
Jeff Haynie & Jeff English & Vijay Singh

## Module History
View the [change log](changelog.html) for this module.

## Feedback and Support
Please direct all questions, feedback, and concerns to [info@appcelerator.com](mailto:info@appcelerator.com?subject=iOS%20Barcode%20Module).

## License
Copyright(c) 2010-2018 by Appcelerator, Inc. All Rights Reserved. Please see the LICENSE file included in the distribution for further details.
