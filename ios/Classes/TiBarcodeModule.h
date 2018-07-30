/**
 * Ti.BarcodeScanner
 * Copyright (c) 2017-present by Hans Knöchel. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiModule.h"
#import "TiBarcodeViewController.h"
#import "MTBBarcodeScanner.h"
@class OverlayView1;

@interface TiBarcodeModule : TiModule <CancelDelegate>{
    TiBarcodeViewController *barcodeViewController;
    
    MTBCamera selectedCamera;
    
    MTBTorchMode selectedLEDMode;
    
    BOOL allowRotation;
    
    NSString *displayedMessage;
}

- (id)canShow:(id)unused;

- (void)capture:(id)args;

- (void)freezeCapture:(id)unused;

- (void)unfreezeCapture:(id)unused;

- (void)captureStillImage:(id)value;

- (void)cancel:(id)unused;

- (void)setUseLED:(id)value;

- (id)useLED;

- (void)setAllowRotation:(id)value;

- (void)setUseFrontCamera:(id)value;

- (id)useFrontCamera;

@end
