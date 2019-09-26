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
			// FIXME: Support CODE_93 and CODE_39_MOD_43 on Android!
			if (IOS) {
				it('FORMAT_CODE_93', () => {
					expect(Barcode.FORMAT_CODE_93).toEqual(jasmine.any(Number));
				});
				it('FORMAT_CODE_39_MOD_43', () => {
					expect(Barcode.FORMAT_CODE_39_MOD_43).toEqual(jasmine.any(Number));
				});
			}
			it('FORMAT_ITF', () => {
				expect(Barcode.FORMAT_ITF).toEqual(jasmine.any(Number));
			});
			// FIXME: Support PDF_417 and INTERLEAVED_2_OF_5 on Android!
			if (IOS) {
				it('FORMAT_PDF_417', () => {
					expect(Barcode.FORMAT_PDF_417).toEqual(jasmine.any(Number));
				});
				it('FORMAT_INTERLEAVED_2_OF_5', () => {
					expect(Barcode.FORMAT_INTERLEAVED_2_OF_5).toEqual(jasmine.any(Number));
				});
			}
			it('FORMAT_AZTEC', () => {
				expect(Barcode.FORMAT_AZTEC).toEqual(jasmine.any(Number));
			});

			it('FORMAT_RSS_14', () => {
				expect(Barcode.FORMAT_RSS_14).toEqual(jasmine.any(Number));
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
		// FIXME: iOS has  ahuge feature parity issue between the capture and parse methods.
		// They use totally different APIs, and parse() can really only pick up QR codes.
		// While capture uses AVFoundation and can pick up a much wider array of codes.
		// Android meanwhile uses zxing, and seems to handle even a wider array of code types
		describe('.parse()', () => {
			// Try out a number of samples from: https://commons.wikimedia.org/wiki/Barcode
			it('is a Function', () => {
				expect(Barcode.parse).toEqual(jasmine.any(Function));
			});

			function testBarcode(filename, format, result, contentType, finish) {
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
				Barcode.parse({ image, acceptedFormats: [ format ] });
			}

			// TODO: Generate some barcodes encoding multiple content types:
			// https://zxing.appspot.com/generator

			it('finds a Code 39 barcode in a blob image', finish => {
				testBarcode(
					'Code39Barcode.jpg',
					Barcode.FORMAT_CODE_39,
					'12345F',
					Barcode.TEXT,
					finish);
			});

			it('finds a Code 93 barcode in a blob image', finish => {
				testBarcode(
					'Code_93.png',
					Barcode.FORMAT_CODE_93,
					'WIKIPEDIA',
					Barcode.TEXT,
					finish);
			});

			it('finds a Code 128 barcode in a blob image', finish => {
				testBarcode(
					'Code128Barcode.jpg',
					Barcode.FORMAT_CODE_128,
					'12345678',
					Barcode.TEXT,
					finish);
			});

			it('finds an EAN 13 barcode with rest indicator in a blob image', finish => {
				testBarcode(
					'EAN-13-5901234123457.png',
					Barcode.FORMAT_EAN_13,
					'5901234123457',
					Barcode.TEXT,
					finish);
			});

			it('finds an EAN 8 barcode in a blob image', finish => {
				testBarcode(
					'EAN8Barcode.jpg',
					Barcode.FORMAT_EAN_8,
					'12345670',
					Barcode.TEXT,
					finish);
			});

			it('finds a UPC A barcode in a blob image', finish => {
				testBarcode(
					'UPC-A-036000291452.png',
					Barcode.FORMAT_UPC_A,
					'036000291452',
					Barcode.TEXT,
					finish);
			});

			it('finds a UPC E barcode in a blob image', finish => {
				testBarcode(
					'upc-e.jpg',
					Barcode.FORMAT_UPC_E,
					'04252614',
					Barcode.TEXT,
					finish);
			});

			it('finds an ITF 14 barcode in a blob image', finish => {
				testBarcode(
					'itf14_barcode.jpg',
					Barcode.FORMAT_ITF,
					'00012345678905',
					Barcode.TEXT,
					finish);
			});

			it('finds an Interleaved 2 of 5 barcode in a blob image', finish => {
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

			it('finds an Aztec barcode in a blob image', finish => {
				testBarcode(
					'Code-aztec.png',
					Barcode.FORMAT_AZTEC,
					'ZXing:http://code.google.com/p/zxing & http;//tinyurl.com/gcode-site/p/zxing = PHP:http://www.php.net = Google Code:http://code.google.com & http://tinyurl.com/gcode-site TinyURL:http://tinyurl.com = Mozilla:http://www.mozilla.org',
					Barcode.TEXT,
					finish);
			});

			it('finds a PDF-417 barcode in a blob image', finish => {
				testBarcode(
					'Better_Sample_PDF417.png',
					Barcode.FORMAT_PDF_417,
					'PDF417 is a stacked linear barcode symbol format used in a variety of applications, primarily transport, identification cards, and inventory management.',
					Barcode.TEXT,
					finish);
			});

			it('finds a QR Code barcode in a Wikipedia blob image', finish => {
				testBarcode(
					'Wikipedia_QR-Code.png',
					Barcode.FORMAT_QR_CODE,
					'http://wikipedia.org/',
					Barcode.URL,
					finish);
			});

			it('finds a QR Code barcode in a blob image', finish => {
				testBarcode(
					'QRCode.png',
					Barcode.FORMAT_QR_CODE,
					'QR Code',
					Barcode.TEXT,
					finish);
			});

			it('finds a Codabar barcode in a blob image', finish => {
				testBarcode(
					'Rationalized-codabar.png',
					Barcode.FORMAT_CODABAR,
					'137255',
					Barcode.TEXT,
					finish);
			});

			it('finds a Maxicode barcode in a blob image', finish => {
				testBarcode(
					'1024px-MaxiCode.png', // FIXME: Does not scan on Android, scans online at https://zxing.org/w/decode.jspx
					Barcode.FORMAT_MAXICODE,
					'Wikipedia, the free encyclopedia',
					Barcode.TEXT,
					finish);
			});

			// TODO: Try: https://www.barcodefaq.com/wp-content/uploads/2018/08/maxicode-ups-example.gif
			// 

			it('finds a Data Matrix barcode in a blob image', finish => {
				testBarcode(
					'Datamatrix.png',
					Barcode.FORMAT_DATA_MATRIX,
					'Wikipedia, the free encyclopedia',
					Barcode.TEXT,
					finish);
			});

			xit('finds a Data Matrix barcode in a blob USPS Pitney Bowes image', finish => {
				testBarcode(
					'DataMatrix_US_franking_mark12.jpg',
					Barcode.FORMAT_DATA_MATRIX,
					 // FIXME: text is garbled/invalid (which busts things when we try to print it!)
					'��$ÂÐ�021Aùâ)�3åm�N���B2���������������Í¹2�0000Z­A�Å[�Ý�¿oÉ�ý¼à�s)0ëKÓ��$¿öý)y�ÞÕ',
					Barcode.TEXT,
					finish);
			});

			it('finds an RSS-14 barcode in a blob image', finish => {
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
