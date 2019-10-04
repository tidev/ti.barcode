let Barcode;

const IOS = (Ti.Platform.osname === 'iphone' || Ti.Platform.osname === 'ipad');
const ANDROID = (Ti.Platform.osname === 'android');

describe('ti.barcode', function () {

	it('can be required', () => {
		Barcode = require('ti.barcode');
		expect(Barcode).toBeDefined();
	});

	it('.apiName', () => {
		expect(Barcode.apiName).toBe('Ti.Barcode');
	});

	describe('constants', () => {
		describe('FORMAT_*', () => {
			it('FORMAT_NONE', () => {
				expect(Barcode.FORMAT_NONE).toEqual(jasmine.any(Number));
			});

			it('FORMAT_QR_CODE', () => {
				expect(Barcode.FORMAT_QR_CODE).toEqual(jasmine.any(Number));
			});

			it('FORMAT_DATA_MATRIX', () => {
				expect(Barcode.FORMAT_DATA_MATRIX).toEqual(jasmine.any(Number));
			});

			it('FORMAT_UPC_E', () => {
				expect(Barcode.FORMAT_UPC_E).toEqual(jasmine.any(Number));
			});

			it('FORMAT_UPC_A', () => {
				expect(Barcode.FORMAT_UPC_A).toEqual(jasmine.any(Number));
			});

			it('FORMAT_EAN_8', () => {
				expect(Barcode.FORMAT_EAN_8).toEqual(jasmine.any(Number));
			});

			it('FORMAT_EAN_13', () => {
				expect(Barcode.FORMAT_EAN_13).toEqual(jasmine.any(Number));
			});

			it('FORMAT_CODE_128', () => {
				expect(Barcode.FORMAT_CODE_128).toEqual(jasmine.any(Number));
			});

			it('FORMAT_CODE_39', () => {
				expect(Barcode.FORMAT_CODE_39).toEqual(jasmine.any(Number));
			});

			// FIXME: Treat equivalent to CODE_39? Also set special hint for assumeCode39CheckDigit?
			it('FORMAT_CODE_39_MOD_43', () => {
				expect(Barcode.FORMAT_CODE_39_MOD_43).toEqual(jasmine.any(Number));
			});

			it('FORMAT_CODE_93', () => {
				expect(Barcode.FORMAT_CODE_93).toEqual(jasmine.any(Number));
			});

			it('FORMAT_ITF', () => {
				expect(Barcode.FORMAT_ITF).toEqual(jasmine.any(Number));
			});

			// This is deprecated and equivalent to ITF now!
			it('INTERLEAVED_2_OF_5', () => {
				expect(Barcode.FORMAT_INTERLEAVED_2_OF_5).toEqual(jasmine.any(Number));
			});

			it('FORMAT_PDF_417', () => {
				expect(Barcode.FORMAT_PDF_417).toEqual(jasmine.any(Number));
			});

			it('FORMAT_AZTEC', () => {
				expect(Barcode.FORMAT_AZTEC).toEqual(jasmine.any(Number));
			});

			it('FORMAT_RSS_14', () => {
				expect(Barcode.FORMAT_RSS_14).toEqual(jasmine.any(Number));
			});

			it('FORMAT_RSS_EXPANDED', () => {
				expect(Barcode.FORMAT_RSS_EXPANDED).toEqual(jasmine.any(Number));
			});
		});

		describe('contentType values', () => {
			it('UNKNOWN', () => {
				expect(Barcode.UNKNOWN).toEqual(0);
			});
			it('URL', () => {
				expect(Barcode.URL).toEqual(1);
			});
			it('SMS', () => {
				expect(Barcode.SMS).toEqual(2);
			});
			it('TELEPHONE', () => {
				expect(Barcode.TELEPHONE).toEqual(3);
			});
			it('TEXT', () => {
				expect(Barcode.TEXT).toEqual(4);
			});
			it('CALENDAR', () => {
				expect(Barcode.CALENDAR).toEqual(5);
			});
			it('GEOLOCATION', () => {
				expect(Barcode.GEOLOCATION).toEqual(6);
			});
			it('EMAIL', () => {
				expect(Barcode.EMAIL).toEqual(7);
			});
			it('CONTACT', () => {
				expect(Barcode.CONTACT).toEqual(8);
			});
			it('BOOKMARK', () => {
				expect(Barcode.BOOKMARK).toEqual(9);
			});
			it('WIFI', () => {
				expect(Barcode.WIFI).toEqual(10);
			});
		});
	});

	describe('properties', () => {
		if (ANDROID) {
			describe('.allowMenu', () => {
				it('defaults to true', () => {
					expect(Barcode.allowMenu).toEqual(true);
				});
			});

			describe('.allowInstructions', () => {
				it('defaults to true', () => {
					expect(Barcode.allowInstructions).toEqual(true);
				});
			});
		}

		describe('.displayedMessage', () => {
			it('defaults to undefined', () => {
				expect(Barcode.displayedMessage).not.toBeDefined();
			});
		});

		describe('.useFrontCamera', () => {
			it('defaults to false', () => {
				expect(Barcode.useFrontCamera).toEqual(false);
			});
		});

		describe('.useLED', () => {
			it('defaults to false', () => {
				expect(Barcode.useLED).toEqual(false);
			});
		});
	});

	describe('methods', () => {
		describe('.cancel()', () => {
			it('is a Function', () => {
				expect(Barcode.cancel).toEqual(jasmine.any(Function));
			});
		});

		if (IOS) {
			// TODO: Deprecated
			describe('.canShow()', () => {
				it('is a Function', () => {
					expect(Barcode.canShow).toEqual(jasmine.any(Function));
				});

				it('returns Boolean', () => {
					expect(Barcode.canShow()).toEqual(jasmine.any(Boolean));
				});
			});
		}

		describe('.capture()', () => {
			it('is a Function', () => {
				expect(Barcode.capture).toEqual(jasmine.any(Function));
			});
			// TODO: Can we test capturing? I assume it needs permissions...
		});

		// TODO: ios has: freezeCapture(), unfreezeCapture(), captureStillImage()
		// FIXME: iOS has a huge feature parity issue between the capture and parse methods.
		// They use totally different APIs, and parse() can really only pick up QR codes.
		// While capture uses AVFoundation and can pick up a much wider array of codes.
		// Android meanwhile uses zxing, and seems to handle even a wider array of code types
		describe('.parse()', () => {
			// Try out a number of samples from: https://commons.wikimedia.org/wiki/Barcode
			it('is a Function', () => {
				expect(Barcode.parse).toEqual(jasmine.any(Function));
			});

			function testBarcode(filename, format, result, contentType, hints, finish) {
				if (typeof hints === 'function') {
					finish = hints;
					hints = {};
				}
				// FIXME: Use getAsset on ios so we don't need to turn off app thinning?
				const image = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, `images/${filename}`).read();
				function error(err) {
					Barcode.removeEventListener('success', success);
					Barcode.removeEventListener('error', error);
					finish.fail(err);
				}

				function success(obj) {
					Barcode.removeEventListener('success', success);
					Barcode.removeEventListener('error', error);
					console.log(`${filename}, ${format}:`);
					console.log(obj);
					try {
						expect(obj).toEqual(jasmine.objectContaining({
							format,
							result,
							contentType
							// TODO: Check code? data?
						}));
						finish();
					} catch (err) {
						finish.fail(err);
					}
				}
				Barcode.addEventListener('error', error);
				Barcode.addEventListener('success', success);
				Barcode.parse(Object.assign(hints, { image, acceptedFormats: [ format ] }));
			}

			describe('finds structured contentTypes in QR codes', () => {
				it('CALENDAR', finish => {
					// TODO: Test parsed data too!
					// FIXME: Why does this have windows newlines?
					testBarcode(
						'event.png',
						Barcode.FORMAT_QR_CODE,
						'BEGIN:VEVENT\r\nSUMMARY:Testing an Event\r\nDTSTART:20190926T155900Z\r\nDTEND:20191003T165900Z\r\nLOCATION:Test Location\r\nDESCRIPTION:Testing a QR code calendar event\r\nEND:VEVENT\r\n',
						Barcode.CALENDAR,
						finish);
				});

				it('CONTACT', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'vcard.png',
						Barcode.FORMAT_QR_CODE,
						'BEGIN:VCARD\nVERSION:3.0\nN:Chris Williams\nORG:Axway\nTITLE:Principal Software Architect II\nTEL:5855551234\nURL:http://www.axway.com\nEMAIL:cwilliams@axway.com\nADR:123 Main Street\nNOTE:memo\nEND:VCARD',
						Barcode.CONTACT,
						finish);
				});

				it('EMAIL', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'email.png',
						Barcode.FORMAT_QR_CODE,
						'mailto:cwilliams@axway.com',
						Barcode.EMAIL,
						finish);
				});

				it('GEOLOCATION', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'geo.png',
						Barcode.FORMAT_QR_CODE,
						'geo:38.8977,77.0365?q=White House',
						Barcode.GEOLOCATION,
						finish);
				});

				it('TELEPHONE', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'phone.png',
						Barcode.FORMAT_QR_CODE,
						'tel:5855551234',
						Barcode.TELEPHONE,
						finish);
				});

				it('SMS', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'sms.png',
						Barcode.FORMAT_QR_CODE,
						'smsto:5855551234:This is a test message!',
						Barcode.SMS,
						finish);
				});

				it('URL', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'url.png',
						Barcode.FORMAT_QR_CODE,
						'http://www.axway.com',
						Barcode.URL,
						finish);
				});

				it('WIFI', finish => {
					// TODO: Test parsed data too!
					testBarcode(
						'wifi.png',
						Barcode.FORMAT_QR_CODE,
						'WIFI:S:secret-wifi;T:WPA;P:secretp455w0rD;H:true;;',
						Barcode.WIFI,
						finish);
				});
			});

			describe('finds various formats of barcodes from blob image', () => {
				it('CODE_39', finish => {
					testBarcode(
						'Code39Barcode.jpg',
						Barcode.FORMAT_CODE_39,
						'12345F',
						Barcode.TEXT,
						finish);
				});

				it('CODE_93', finish => {
					testBarcode(
						'Code_93.png',
						Barcode.FORMAT_CODE_93,
						'WIKIPEDIA',
						Barcode.TEXT,
						finish);
				});

				it('CODE_128', finish => {
					testBarcode(
						'Code128Barcode.jpg',
						Barcode.FORMAT_CODE_128,
						'12345678',
						Barcode.TEXT,
						finish);
				});

				it('EAN_13 barcode with rest indicator', finish => {
					testBarcode(
						'EAN-13-5901234123457.png',
						Barcode.FORMAT_EAN_13,
						'5901234123457',
						Barcode.TEXT,
						finish);
				});

				it('EAN_8', finish => {
					testBarcode(
						'EAN8Barcode.jpg',
						Barcode.FORMAT_EAN_8,
						'12345670',
						Barcode.TEXT,
						finish);
				});

				it('UPC_A', finish => {
					testBarcode(
						'UPC-A-036000291452.png',
						Barcode.FORMAT_UPC_A,
						'036000291452',
						Barcode.TEXT,
						finish);
				});

				it('UPC_E', finish => {
					testBarcode(
						'upc-e.jpg',
						Barcode.FORMAT_UPC_E,
						'04252614',
						Barcode.TEXT,
						finish);
				});

				it('ITF 14', finish => {
					testBarcode(
						'itf14_barcode.jpg',
						Barcode.FORMAT_ITF,
						'00012345678905',
						Barcode.TEXT,
						finish);
				});

				it('INTERLEAVED_2_OF_5', finish => {
					testBarcode(
						'I2of5Barcode.jpg',
						// FIXME: We have this defined as a separate constant, but ITF stands for "Interleaved Two of Five"
						// So ITF should be correct!
						// Barcode.FORMAT_INTERLEAVED_2_OF_5,
						Barcode.FORMAT_ITF,
						'161718',
						Barcode.TEXT,
						finish);
				});

				it('AZTEC', finish => {
					testBarcode(
						'Code-aztec.png',
						Barcode.FORMAT_AZTEC,
						'ZXing:http://code.google.com/p/zxing & http;//tinyurl.com/gcode-site/p/zxing = PHP:http://www.php.net = Google Code:http://code.google.com & http://tinyurl.com/gcode-site TinyURL:http://tinyurl.com = Mozilla:http://www.mozilla.org',
						Barcode.TEXT,
						finish);
				});

				it('PDF-417', finish => {
					testBarcode(
						'Better_Sample_PDF417.png',
						Barcode.FORMAT_PDF_417,
						'PDF417 is a stacked linear barcode symbol format used in a variety of applications, primarily transport, identification cards, and inventory management.',
						Barcode.TEXT,
						finish);
				});

				it('QR_CODE - Wikipedia', finish => {
					testBarcode(
						'Wikipedia_QR-Code.png',
						Barcode.FORMAT_QR_CODE,
						'http://wikipedia.org/',
						Barcode.URL,
						finish);
				});

				it('QR_CODE', finish => {
					testBarcode(
						'QRCode.png',
						Barcode.FORMAT_QR_CODE,
						'QR Code',
						Barcode.TEXT,
						finish);
				});

				it('CODABAR', finish => {
					testBarcode(
						'Rationalized-codabar.png',
						Barcode.FORMAT_CODABAR,
						'137255',
						Barcode.TEXT,
						finish);
				});

				// FIXME: Does not scan on Android/iOS, scans online at https://zxing.org/w/decode.jspx
				xit('MAXICODE', finish => {
					testBarcode(
						'1024px-MaxiCode.png',
						Barcode.FORMAT_MAXICODE,
						'Wikipedia, the free encyclopedia',
						Barcode.TEXT,
						finish);
				});

				it('MAXICODE - UPS', finish => {
					testBarcode(
						'maxicode-ups-example.gif',
						Barcode.FORMAT_MAXICODE,
						'[)>�01�96336091062�840�002�1Z14647438�UPSN�410E1W�195��1/1��Y�135Reo�\n\nTAMPA�FL��',
						Barcode.TEXT,
						finish);
				});

				it('DATA_MATRIX', finish => {
					testBarcode(
						'Datamatrix.png',
						Barcode.FORMAT_DATA_MATRIX,
						'Wikipedia, the free encyclopedia',
						Barcode.TEXT,
						finish);
				});

				xit('DATA_MATRIX - USPS Pitney Bowes', finish => {
					testBarcode(
						'DataMatrix_US_franking_mark12.jpg',
						Barcode.FORMAT_DATA_MATRIX,
						// FIXME: text is garbled/invalid (which busts things when we try to print it!)
						'��$ÂÐ�021Aùâ)�3åm�N���B2���������������Í¹2�0000Z­A�Å[�Ý�¿oÉ�ý¼à�s)0ëKÓ��$¿öý)y�ÞÕ',
						Barcode.TEXT,
						finish);
				});

				it('RSS-14', finish => {
					testBarcode(
						'RSS_14-Databar_14_00075678164125.png',
						Barcode.FORMAT_RSS_14,
						'00075678164125',
						Barcode.TEXT,
						finish);
				});
			});

			describe('supports hints', () => {
				it('MAXICODE', finish => {
					testBarcode(
						'1024px-MaxiCode.png',
						Barcode.FORMAT_MAXICODE,
						'Wikipedia, the free encyclopedia',
						Barcode.TEXT,
						{ pureBarcode: true },
						finish);
				});

				it('MAXICODE - UPS', finish => {
					testBarcode(
						'maxicode-ups-example.gif',
						Barcode.FORMAT_MAXICODE,
						'[)>�01�96336091062�840�002�1Z14647438�UPSN�410E1W�195��1/1��Y�135Reo�\n\nTAMPA�FL��',
						Barcode.TEXT,
						{ pureBarcode: true },
						finish);
				});
			});
			// TODO: Pass in various hints/arguments! assumeGS1, tryHarder, characterSet, returnCodabarStartEnd, assumeCode39CheckDigit, allowedLengths, allowedEANExtensions
		});
	});
});
