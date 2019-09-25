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
			// FIXME: Support PDF_417, AZTEC, and INTERLEAVED_2_OF_5 on Android!
			if (IOS) {
				it('FORMAT_PDF_417', () => {
					expect(Barcode.FORMAT_PDF_417).toEqual(jasmine.any(Number));
				});
				it('FORMAT_AZTEC', () => {
					expect(Barcode.FORMAT_AZTEC).toEqual(jasmine.any(Number));
				});
				it('FORMAT_INTERLEAVED_2_OF_5', () => {
					expect(Barcode.FORMAT_INTERLEAVED_2_OF_5).toEqual(jasmine.any(Number));
				});
			}
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

		describe('.parse()', () => {
			it('is a Function', () => {
				expect(Barcode.parse).toEqual(jasmine.any(Function));
			});

			function testBarcodeViaURL(url, format, data, finish) {
				// FIXME: Include some image files with barcodes in the test app rather than downloading them
				// const imageBlob = Ti.Filesystem.getFile().read();
				const client = Ti.Network.createHTTPClient({
					onload: function(e) {
						function error(err) {
							Barcode.removeEventListener('error', error);
							finish(err);
						}

						function success(obj) {
							Barcode.removeEventListener('success', success);
							console.log(obj);
							try {
								expect(obj.format).toEqual(format);
								// dict.put("result", contents);
								// dict.put("code", resultCode);
								expect(obj.contentType).toEqual(Barcode.TEXT);
								// dict.put("data", parseData(contentType, contents));
								finish();
							} catch (err) {
								finish.fail(err);
							}
						}
						Barcode.addEventListener('error', error);
						Barcode.addEventListener('success', success);
						Barcode.parse({ image: this.responseData });
					},
					onerror: e => finish.fail(e),
					timeout: 5000
				});
				client.open('GET', url);
				client.send();
			}

			it('finds a Code 39 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/Code39Barcode.jpg',
					Barcode.FORMAT_CODE_39, // FIXME: Android reports format as 'CODE_39' rather than constant
					'12345F',
					finish);
			});

			it('finds a Code 128 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/Code128Barcode.jpg',
					Barcode.FORMAT_CODE_128, // FIXME: Android reports format as 'CODE_128' rather than constant
					'12345678',
					finish);
			});

			it('finds an EAN 13 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/EAN13Barcode.jpg',
					Barcode.FORMAT_EAN_13, // FIXME: This appears to be the same as EAN8 on Android?
					'12345670', // FIXME: Should be '1234567890128'
					finish);
			});

			it('finds an EAN 8 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/EAN8Barcode.jpg',
					Barcode.FORMAT_EAN_8,// FIXME: Android reports format as 'EAN_8' rather than constant
					'12345670',
					finish);
			});

			it('finds a UPC A barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/UPCABarcode.jpg',
					Barcode.FORMAT_UPC_A, // FIXME: This appears to be the same as 'ITF' on Android?
					'00012345678905',
					finish);
			});

			it('finds a UPC E barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/UPCEBarcode.jpg',
					Barcode.FORMAT_UPC_E, // FIXME: This appears to be the same as 'ITF' on Android?
					'00012345678905', // FIXME: should be '01234565'
					finish);
			});

			it('finds an ITF 14 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/itf14_barcode.jpg',
					Barcode.FORMAT_ITF,
					'00012345678905',
					finish);
			});

			it('finds an Interleaved 2 of 5 barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://www.barcoderesource.com/images/I2of5Barcode.jpg',
					Barcode.FORMAT_INTERLEAVED_2_OF_5,// FIXME: Android reports format as 'ITF' rather than constant
					'161718',
					finish);
			});

			it('finds an Aztec barcode in a blob image', finish => {
				testBarcodeViaURL(
					'https://upload.wikimedia.org/wikipedia/commons/e/ec/Code-aztec.png',
					Barcode.FORMAT_AZTEC,// FIXME: Android reports format as 'AZTEC' rather than constant, constant is undefined
					'ZXing:http://code.google.com/p/zxing & http;//tinyurl.com/gcode-site/p/zxing = PHP:http://www.php.net = Google Code:http://code.google.com & http://tinyurl.com/gcode-site TinyURL:http://tinyurl.com = Mozilla:http://www.mozilla.org',
					finish);
			});

			// TODO: QR Code
			// TODO: Data Matrix
			// TODO: FORMAT_CODE_93
			// TODO: FORMAT_CODE_39_MOD_43
			// TODO: FORMAT_PDF_417

		});
	});
});
