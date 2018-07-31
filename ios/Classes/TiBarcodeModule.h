/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "MTBBarcodeScanner.h"
#import "TiBarcodeViewController.h"
#import "TiModule.h"
@class TiOverlayView;

@interface TiBarcodeModule : TiModule <TiOverlayViewDelegate> {
  TiBarcodeViewController *barcodeViewController;
  MTBCamera selectedCamera;
  MTBTorchMode selectedLEDMode;
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
