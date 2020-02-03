# v5.0.0

## BREAKING CHANGES

- The `success` event's `format` property is now reported as a Number - matching the `FORMAT_*` constants defined on this module. If for some reason no such constant is found, the format will be reported through as a String value returned by the zxing library.

## Deprecations
- The `FORMAT_CODE_39_MOD_43` constant is deprecated and is treated as equivalent to specifying `FORMAT_CODE_39`
  - The methods now take in hints for decoding passed into the `#parse()` and `#capture()` methods. Pass along the `assumeCode39CheckDigit: true` hint in the options to enforce check digits.
- The `FORMAT_INTERLEAVED_2_OF_5` constant is deprecated and is treated as equivalent to specifying `FORMAT_ITF`
- The `FORMAT_NONE` constant is deprecated. When passing along `acceptedFormats`, use an empty array instead or don't specify formats (zxing will default to *all* formats)

## New Features
- Both `#capture()` and `#parse()` now accept a number of decoding hints that may be passed along to zxing. In some cases, these are required to be able to detect particular formats of barcodes (i.e. You must pass along `pureBarcode: true` for `FORMAT_MAXICODE`, due to the "beta" level of support for this format in zxing - which also implies that the input is a pure monochrome barcode image)

For example:
```javascript
const image = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, 'barcode.png').read();
Barcode.addEventListener('sucecss', function(obj) {
    // TODO: handle success event...
});
Barcode.parse({
    image: image,
    assumeGS1: true,
    tryHarder: true,
    returnCodabarStartEnd: true,
    assumeCode39CheckDigit: true
});
```

## Known Issues
While there is now a `assumeGS1` hint that may be passed in to `#capture()` and `#parse()`, it is not consistently applied by zxing. It appears to only affect `FORMAT_CODE_128` barcodes, and only places the `']C1'` prefix in front of GS1 barcodes (it does not pre-pend `']C0'` for non-GS1, nor does it affect other formats like `FORMAT_DATA_MATRIX` to insert the `']d2'` or `']d1'` prefixes)

## iOS

The iOS implementation has been rebuilt on top of zxing again to match the Android implementation, and to provide a wider range of supported formats, decode hints, and a `#parse()` implementation consistent with `#capture()` results.
