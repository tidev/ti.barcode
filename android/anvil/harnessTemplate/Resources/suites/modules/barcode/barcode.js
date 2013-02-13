/*
 * Appcelerator Titanium Mobile
 * Copyright (c) 2011-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

module.exports = new function () {
    var finish;
    var valueOf;
    var Barcode;
    this.init = function (testUtils) {
        finish = testUtils.finish;
        valueOf = testUtils.valueOf;
        Barcode = require('ti.barcode');
    };

    this.name = "barcode";
    this.tests = [
        {name:"barcodeModule"},
        {name:"capture"}
    ];

    // Test that module is loaded
    this.barcodeModule = function (testRun) {
        // Verify that the module is defined
        valueOf(testRun, Barcode).shouldBeObject();
        finish(testRun);
    },

        // Test the usage of the useSecure property
        this.capture = function (testRun) {
            var cancelled = function (e) {
                Barcode.removeEventListener('cancel', cancelled);
                finish(testRun);
            };

            var cancelCapture = function (e) {
                Barcode.cancel();
            }

            Barcode.capture();
            Barcode.addEventListener('cancel', cancelled);
            setTimeout(cancelCapture, 5000);
        }
}
