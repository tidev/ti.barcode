# Titanium Barcode Module [![Build Status](https://jenkins.appcelerator.org/buildStatus/icon?job=modules%2Fti.barcode%2Fmaster)](https://jenkins.appcelerator.org/job/modules/job/ti.barcode/job/master/) [![@titanium-sdk/ti.barcode](https://img.shields.io/npm/v/@titanium-sdk/ti.barcode.png)](https://www.npmjs.com/package/@titanium-sdk/ti.barcode)

This is the Barcode Module for Titanium built on top of the ZXing library (Android)
and AVFoundation (iOS).

## Scan area (`frameWidth` / `frameHeight`)

`capture()` accepts `frameWidth` and `frameHeight` (in dp on Android, points on iOS) to size
the scan area — a centered rectangle that controls **both** the drawn viewfinder and the region
that is actually decoded. Barcodes outside the rectangle are ignored.

This is the tool for isolating one barcode on a dense sheet: use a thin, wide rectangle and aim
its red laser line at the barcode you want, like a scanner gun.

```javascript
const Barcode = require('ti.barcode');

// Thin "laser slit" — decodes only the 1D barcode under the line:
Barcode.capture({
  frameWidth: 300,
  frameHeight: 50,
  acceptedFormats: [Barcode.FORMAT_CODE_128, Barcode.FORMAT_CODE_39]
});

// Square area for QR codes:
Barcode.capture({
  frameWidth: 250,
  frameHeight: 250,
  acceptedFormats: [Barcode.FORMAT_QR_CODE]
});
```

Without these options the scan area falls back to the platform default (a large centered
rectangle). The values are read when `capture()` is launched; to change the area, relaunch
the scanner.

## Viewfinder and custom overlays

The module always renders a native viewfinder: a rectangle around the scan area, a red laser
line through its middle, and a dark mask outside it. Related `capture()` options:

| Option | Effect |
| --- | --- |
| `showRectangle: false` | Hides the native viewfinder entirely (rectangle, laser and mask). The scan area still applies. |
| `showCancel: false` | Hides the native cancel button (iOS). |
| `displayedMessage` | Replaces the instruction text drawn above the rectangle. |
| `overlay` | A Titanium view rendered on top of the camera (and of the native viewfinder, if shown). |

To use a fully custom overlay without the native drawing showing through:

```javascript
Barcode.capture({
  showRectangle: false, // no native rectangle/laser/mask
  showCancel: false,
  frameWidth: 300,      // the decode region still honors these —
  frameHeight: 50,      // draw your own box centered at this exact size
  overlay: myOverlayView
});
```

Note: the decoded region keeps honoring `frameWidth`/`frameHeight` even with
`showRectangle: false`, so draw your custom viewfinder centered and with those same
dimensions or your UI will not match what is actually scanned.

## Scan feedback

Each newly decoded value plays a short system beep on both platforms (on iOS it is
deduplicated by value, since continuous mode decodes the same barcode on every frame).
For vibration, call `Ti.Media.vibrate()` from your `success` listener — it works on Android
and iPhone; iPads have no vibration motor, which is why the beep exists.

## iOS notes

- The camera captures at 1080p with the autofocus restricted to the near range, per Apple's
  barcode-scanning guidance.
- As of 7.0.0 the iOS module no longer supports Mac Catalyst (`mac: false`) and ships
  `arm64` (device) + `arm64/x86_64` (simulator) slices only.

## Contributors

Interested in contributing? Read the [contributors/committer's](https://wiki.appcelerator.org/display/community/Home) guide.

## Legal

This module is Copyright (c) 2010-present by Appcelerator, Inc. All Rights Reserved. Usage of this module is subject to 
the Terms of Service agreement with Appcelerator, Inc.
