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

		describe('.parse()', () => {
			// Try out a number of samples from: https://commons.wikimedia.org/wiki/Barcode
			it('is a Function', () => {
				expect(Barcode.parse).toEqual(jasmine.any(Function));
			});

			function readBarcode(filename, hints, callback) {
				if (typeof hints === 'function') {
					callback = hints;
					hints = {};
				}
				// FIXME: Use getAsset on ios so we don't need to turn off app thinning?
				const image = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, `images/${filename}`).read();
				function error(err) {
					Barcode.removeEventListener('success', success);
					Barcode.removeEventListener('error', error);
					callback(err);
				}

				function success(obj) {
					Barcode.removeEventListener('success', success);
					Barcode.removeEventListener('error', error);
					callback(null, obj);
				}
				Barcode.addEventListener('error', error);
				Barcode.addEventListener('success', success);
				try {
					const combined = Object.assign(hints, { image });
					Barcode.parse(combined);
				} catch (err) {
					Barcode.removeEventListener('error', error);
					Barcode.removeEventListener('success', success);
					callback(err);
				}
			}

			function testBarcode(filename, format, result, contentType, hints, finish) {
				if (typeof hints === 'function') {
					finish = hints;
					hints = {};
				}
				readBarcode(filename, hints, (err, obj) => {
					if (err) {
						return finish.fail(err);
					}
					try {
						expect(obj).toEqual(jasmine.objectContaining({
							format,
							result,
							contentType
							// TODO: Check code? data?
						}));
						finish();
					} catch (e) {
						finish.fail(e);
					}
				});
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
				// TODO: Try with assumeCode39CheckDigit

				it('CODE_93', finish => {
					testBarcode(
						'Code_93.png',
						Barcode.FORMAT_CODE_93,
						'WIKIPEDIA',
						Barcode.TEXT,
						finish);
				});

				it('CODE_128 - w/o assumeGS1 hint', finish => {
					testBarcode(
						'Code128Barcode.jpg',
						Barcode.FORMAT_CODE_128,
						'12345678',
						Barcode.TEXT,
						finish);
				});

				// FIXME: If we're assuming GS1 here, I believe this is supposed to start with "]C0"
				// But zxing doesn't do that pre-pending for us...
				it('CODE_128 - w/ assumeGS1 hint', finish => {
					testBarcode(
						'Code128Barcode.jpg',
						Barcode.FORMAT_CODE_128,
						'12345678',
						Barcode.TEXT,
						{ assumeGS1: true },
						finish);
				});

				it('CODE_128 - GS1 w/o assumeGS1 hint', finish => {
					testBarcode(
						'GS1-128.png',
						Barcode.FORMAT_CODE_128,
						'01950123456789033103000123',
						Barcode.TEXT,
						finish);
				});

				it('CODE_128 - GS1 w/ assumeGS1 hint', finish => {
					testBarcode(
						'GS1-128.png',
						Barcode.FORMAT_CODE_128,
						']C101950123456789033103000123',
						Barcode.TEXT,
						{ assumeGS1: true },
						finish);
				});

				it('EAN_13 - w/ rest indicator', finish => {
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
					// FIXME: Intermittently fails on iOS, giving '0036000291452' with EAN_13 format!
					// Note that technically an EAN-13 barcode with a leading 0 is equivalent to a UPC-A barcode!
					// see https://www.nationwidebarcode.com/are-upc-a-and-ean-13-the-same/
					// if (IOS) {
					// 	testBarcode(
					// 		'UPC-A-036000291452.png',
					// 		Barcode.FORMAT_EAN_13,
					// 		'0036000291452',
					// 		Barcode.TEXT,
					// 		finish);
					// } else {
					testBarcode(
						'UPC-A-036000291452.png',
						Barcode.FORMAT_UPC_A,
						'036000291452',
						Barcode.TEXT,
						finish);
					// }
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

				it('CODABAR - rationalized', finish => {
					testBarcode(
						'Rationalized-codabar.png',
						Barcode.FORMAT_CODABAR,
						'137255',
						Barcode.TEXT,
						finish);
				});

				it('CODABAR', finish => {
					testBarcode(
						'codabar-40156.gif',
						Barcode.FORMAT_CODABAR,
						'40156',
						Barcode.TEXT,
						finish);
				});

				it('CODABAR w/ returnCodabarStartEnd hint', finish => {
					testBarcode(
						'codabar-40156.gif',
						Barcode.FORMAT_CODABAR,
						'A40156B',
						Barcode.TEXT,
						{ returnCodabarStartEnd: true },
						finish);
				});

				it('CODABAR - reationalized w/ returnCodabarStartEnd hint', finish => {
					testBarcode(
						'Rationalized-codabar.png',
						Barcode.FORMAT_CODABAR,
						'C137255C',
						Barcode.TEXT,
						{ returnCodabarStartEnd: true },
						finish);
				});

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
					// test with actual raw bytes, since trasnlating to text garbles it
					readBarcode('maxicode-ups-example.gif', { pureBarcode: true }, (err, obj) => {
						if (err) {
							return finish.fail(err);
						}
						try {
							expect(Buffer.from(obj.bytes)).toEqual(Buffer.from([
								0x22, 0x2d, 0x17, 0x21, 0x00, 0x15, 0x02, 0x12, 0x0b, 0x00, 0x3b, 0x2a, 0x29, 0x3b, 0x28, 0x1e,
								0x30, 0x31, 0x1d, 0x39, 0x36, 0x31, 0x1a, 0x31, 0x34, 0x36, 0x34, 0x37, 0x34, 0x33, 0x38, 0x1d,
								0x15, 0x10, 0x13, 0x0e, 0x1d, 0x34, 0x31, 0x30, 0x05, 0x31, 0x17, 0x1d, 0x31, 0x39, 0x35, 0x1d,
								0x1d, 0x31, 0x2f, 0x31, 0x1d, 0x1d, 0x19, 0x1d, 0x31, 0x33, 0x35, 0x12, 0x3f, 0x05, 0x0f, 0x1d,
								0x3b, 0x00, 0x3e, 0x0a, 0x3f, 0x14, 0x01, 0x0d, 0x10, 0x01, 0x1d, 0x06, 0x0c, 0x1e, 0x3e, 0x04,
								0x3f, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21, 0x21
							]));
							finish();
						} catch (e) {
							finish.fail(e);
						}
					});
				});

				it('DATA_MATRIX', finish => {
					testBarcode(
						'Datamatrix.png',
						Barcode.FORMAT_DATA_MATRIX,
						'Wikipedia, the free encyclopedia',
						Barcode.TEXT,
						finish);
				});

				// it('DATA_MATRIX - GS1', finish => {
				// 	testBarcode(
				// 		'GS1-DataMatrix.png',
				// 		Barcode.FORMAT_DATA_MATRIX,
				// 		'Wikipedia, the free encyclopedia',
				// 		Barcode.TEXT,
				// 		finish);
				// });

				// Test cases from https://www.packagingdigest.com/bar-coding/pmp-gs1-datamatrix-fnc1-versus-gs-as-the-variable-length-field-separator-character-091116
				// FIXME: In both cases the library reports the use of ASCII code 29 (\u001d) GS (group separator) character
				// Technically the first and second should differ somehow?
				// Also, the first FNC1 character (\u001d) is *supposed* to be replaced by "]d2" when we're assuming GS1 (in the same way that in CODE_128 it gets replaced by "]C1")
				// But zxing doesn't do that (or even look at assumeGS1 for this format!)
				// See https://jira.appcelerator.org/browse/MOD-2481
				it('DATA_MATRIX - GS1 w/ FNC1 encoding', finish => {
					testBarcode(
						'F1vsGSencodingF1.jpg',
						Barcode.FORMAT_DATA_MATRIX,
						'\u001d010031234567890621123456789012\u001d300144',
						Barcode.TEXT,
						{ assumeGS1: true },
						finish);
				});

				it('DATA_MATRIX - GS1 w/ GS encoding', finish => {
					testBarcode(
						'F1vsGSencodingGS.jpg',
						Barcode.FORMAT_DATA_MATRIX,
						'\u001d010031234567890621123456789012\u001d300144',
						Barcode.TEXT,
						{ assumeGS1: true },
						finish);
				});

				it('DATA_MATRIX - USPS Pitney Bowes', finish => {
					// test with actual raw bytes, since trasnlating to text garbles it
					readBarcode('DataMatrix_US_franking_mark12.jpg', (err, obj) => {
						if (err) {
							return finish.fail(err);
						}
						try {
							expect(Buffer.from(obj.bytes)).toEqual(Buffer.from([
								0xe7, 0x85, 0xc1, 0x57, 0x10, 0x44, 0xe8, 0xad, 0x73, 0x0a, 0x9f, 0x45, 0x92, 0x11, 0xed, 0x5a,
								0x22, 0x6a, 0x88, 0x40, 0x46, 0x29, 0x72, 0x07, 0xa4, 0x74, 0xf9, 0x5e, 0x03, 0x25, 0x1e, 0xb3,
								0x49, 0xde, 0x74, 0x0a, 0x9f, 0x37, 0xce, 0x67, 0xf5, 0x8b, 0x21, 0x83, 0x05, 0x13, 0x79, 0x3d,
								0xd2, 0x68, 0xfd, 0xbd, 0xa5, 0x98, 0x65, 0xd6, 0x14, 0x3f, 0x7f, 0xed, 0xc2, 0xfa, 0x3f, 0xf4,
								0x9a, 0x5a, 0x42, 0xb9, 0x0e, 0xc7, 0x82, 0x86, 0xd1, 0x6e, 0xbe, 0xb4, 0xd1, 0x9f, 0xa9, 0xda,
								0x79, 0xa9, 0x76, 0x13, 0xd4, 0xba, 0xed, 0x06, 0xe0, 0x1b, 0x02, 0x81, 0x47, 0xdd, 0x74, 0x0c,
								0xa2, 0x39, 0xcf, 0x66, 0xfc, 0x94, 0x2b, 0xc1, 0x58, 0xee, 0x86, 0x1d, 0xb3, 0x4a, 0xe0, 0x77,
								0x0f, 0xa5
							]));
							finish();
						} catch (e) {
							finish.fail(e);
						}
					});
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
		});
	});
});
