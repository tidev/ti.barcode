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
		if (IOS) {
			describe('.allowRotation', () => {
				it('is a Boolean', () => {
					expect(Barcode.allowRotation).toEqual(jasmine.any(Boolean));
				});
			});
		}

		if (ANDROID) {
			describe('.allowMenu', () => {
				it('is a Boolean', () => {
					expect(Barcode.allowMenu).toEqual(jasmine.any(Boolean));
				});
			});

			describe('.allowInstructions', () => {
				it('is a Boolean', () => {
					expect(Barcode.allowInstructions).toEqual(jasmine.any(Boolean));
				});
			});
		}

		describe('.displayedMessage', () => {
			it('is a String', () => {
				expect(Barcode.displayedMessage).toEqual(jasmine.any(String));
			});
		});

		describe('.useFrontCamera', () => {
			it('is a Boolean', () => {
				expect(Barcode.useFrontCamera).toEqual(jasmine.any(Boolean));
			});
		});

		describe('.useLED', () => {
			it('is a Boolean', () => {
				expect(Barcode.useLED).toEqual(jasmine.any(Boolean));
			});
		});
	});

	describe('methods', () => {
		describe('.cancel()', () => {
			it('is a Function', () => {
				expect(Barcode.cancel).toEqual(jasmine.any(Function));
			});
		});

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

			it('finds a barcode in a blob image', finish => {
				// FIXME: Include some image files with barcodes in the test app!
				const imageBlob = Ti.Filesystem.getFile().read();
				Barcode.addEventListener('error', err => {
					finish(err);
				});
				Barcode.addEventListener('success', obj => {
					// dict.put("format", format);
					// dict.put("result", contents);
					// dict.put("code", resultCode);
					// dict.put("contentType", contentType);
					// dict.put("data", parseData(contentType, contents));
					finish();
				});
				Barcode.parse({ image: imageBlob });
			});
		});
	});
});
