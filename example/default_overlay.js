/**
 * In this example, we'll use the Barcode module to display some information about
 * the scanned barcode.
 */
var Barcode = require('ti.barcode');

Barcode.allowRotation = true;
Barcode.displayedMessage = ' ';
Barcode.allowMenu = false;
Barcode.allowInstructions = false;
Barcode.useLED = true;

var isAndroid = Ti.Platform.osname === 'android';
var isiOS = !isAndroid;

var window = Ti.UI.createWindow({
	backgroundColor: 'white'
});

var scrollView = Ti.UI.createScrollView({
	contentWidth: 'auto',
	contentHeight: 'auto',
	top: 0,
	showVerticalScrollIndicator: true,
	layout: 'vertical'
});

/**
 * Create a button that will trigger the barcode scanner.
 */
var scanCode = Ti.UI.createButton({
	title: 'Scan the Code',
	width: 150,
	height: 60,
	top: 20
});

var cameraPermission = (callback) => {
	if (isAndroid) {
		if (Ti.Media.hasCameraPermissions()) {
			if (callback) {
				callback(true);
			}
		} else {
			Ti.Media.requestCameraPermissions(function (e) {
				if (e.success) {
					if (callback) {
						callback(true);
					}
				} else {
					if (callback) {
						callback(false);
					}
					alert('No camera permission'); // eslint-disable-line no-alert
				}
			});
		}
	}

	if (isiOS) {
		if (callback) {
			callback(true);
		}
	}
};

scanCode.addEventListener('click', function () {
	cameraPermission(function (re) {
		reset();
		// Note: while the simulator will NOT show a camera stream in the simulator, you may still call "Barcode.capture"
		// to test your barcode scanning overlay.
		Barcode.capture({
			animate: true,
			showCancel: true,
			showRectangle: true,
			keepOpen: true
			/* ,
                    acceptedFormats: [
                        Barcode.FORMAT_QR_CODE
                    ]*/
		});
	});
});
scrollView.add(scanCode);

/**
 * Create a button that will show the gallery picker.
 */
var scanImage = Ti.UI.createButton({
	title: 'Scan Image from Gallery',
	width: 150,
	height: 60,
	top: 20
});

scanImage.addEventListener('click', function () {
	reset();
	Ti.Media.openPhotoGallery({
		success: function (evt) {
			Barcode.parse({
				image: evt.media
				/* ,
                                acceptedFormats: [
                                    Barcode.FORMAT_QR_CODE
                                ]*/
			});
		}
	});
});

scrollView.add(scanImage);

/**
 * Now listen for various events from the Barcode module. This is the module's way of communicating with us.
 */

var scannedBarcodes = {},
	scannedBarcodesCount = 0;

function reset() {
	scannedBarcodes = {};
	scannedBarcodesCount = 0;

	scanResult.text = ' ';
	scanContentType.text = ' ';
	scanFormat.text = ' ';
	scanParsed.text = ' ';
}

Barcode.addEventListener('error', function (e) {
	scanContentType.text = ' ';
	scanFormat.text = ' ';
	scanParsed.text = ' ';
	scanResult.text = e.message;
	console.log('An Error occured: ' + e);
});

Barcode.addEventListener('cancel', function (e) {
	Ti.API.info('Cancel received');
});

Barcode.addEventListener('success', function (e) {
	Ti.API.info('Success called with barcode: ' + e.result);
	if (!scannedBarcodes['' + e.result]) {
		scannedBarcodes[e.result] = true;
		scannedBarcodesCount += 1;

		scanResult.text += e.result + ' ';
		scanContentType.text += parseContentType(e.contentType) + ' ';
		scanFormat.text += e.format + ' ';
		scanParsed.text += parseResult(e) + ' ';
	}
});

/**
 * Finally, we'll add a couple labels to the window. When the user scans a barcode, we'll stick information about it in
 * to these labels.
 */
scrollView.add(Ti.UI.createLabel({
	text: 'You may need to rotate the device',
	top: 10,
	height: Ti.UI.SIZE || 'auto',
	width: Ti.UI.SIZE || 'auto'
}));

scrollView.add(Ti.UI.createLabel({
	text: 'Result: ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
}));

var scanResult = Ti.UI.createLabel({
	text: ' ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
});

scrollView.add(scanResult);

scrollView.add(Ti.UI.createLabel({
	text: 'Content Type: ',
	top: 10,
	left: 10,
	textAlign: 'left',
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
}));

var scanContentType = Ti.UI.createLabel({
	text: ' ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
});

scrollView.add(scanContentType);

scrollView.add(Ti.UI.createLabel({
	text: 'Format: ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
}));

var scanFormat = Ti.UI.createLabel({
	text: ' ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
});

scrollView.add(scanFormat);

scrollView.add(Ti.UI.createLabel({
	text: 'Parsed: ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
}));

var scanParsed = Ti.UI.createLabel({
	text: ' ',
	textAlign: 'left',
	top: 10,
	left: 10,
	color: 'black',
	height: Ti.UI.SIZE || 'auto'
});

scrollView.add(scanParsed);

function parseContentType(contentType) {
	switch (contentType) {
		case Barcode.URL:
			return 'URL';
		case Barcode.SMS:
			return 'SMS';
		case Barcode.TELEPHONE:
			return 'TELEPHONE';
		case Barcode.TEXT:
			return 'TEXT';
		case Barcode.CALENDAR:
			return 'CALENDAR';
		case Barcode.GEOLOCATION:
			return 'GEOLOCATION';
		case Barcode.EMAIL:
			return 'EMAIL';
		case Barcode.CONTACT:
			return 'CONTACT';
		case Barcode.BOOKMARK:
			return 'BOOKMARK';
		case Barcode.WIFI:
			return 'WIFI';
		default:
			return 'UNKNOWN';
	}
}

function parseResult(event) {
	var msg = '';
	switch (event.contentType) {
		case Barcode.URL:
			msg = 'URL = ' + event.result;
			break;
		case Barcode.SMS:
			msg = 'SMS = ' + JSON.stringify(event.data);
			break;
		case Barcode.TELEPHONE:
			msg = 'Telephone = ' + event.data.phonenumber;
			break;
		case Barcode.TEXT:
			msg = 'Text = ' + event.result;
			break;
		case Barcode.CALENDAR:
			msg = 'Calendar = ' + JSON.stringify(event.data);
			break;
		case Barcode.GEOLOCATION:
			msg = 'Geo = ' + JSON.stringify(event.data);
			break;
		case Barcode.EMAIL:
			msg = 'Email = ' + event.data.email + '\nSubject = ' + event.data.subject + '\nMessage = ' + event.data.message;
			break;
		case Barcode.CONTACT:
			msg = 'Contact = ' + JSON.stringify(event.data);
			break;
		case Barcode.BOOKMARK:
			msg = 'Bookmark = ' + JSON.stringify(event.data);
			break;
		case Barcode.WIFI:
			return 'WIFI = ' + JSON.stringify(event.data);
		default:
			msg = 'unknown content type';
			break;
	}
	return msg;
}

window.add(scrollView);
window.open();
