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
  @private
  TiBarcodeViewController *_barcodeViewController;
  MTBCamera _selectedCamera;
  MTBTorchMode _selectedLEDMode;
  NSString *_displayedMessage;
}

- (NSNumber *)canShow:(id)unused;

- (void)capture:(id)args;

- (void)freezeCapture:(id)unused;

- (void)unfreezeCapture:(id)unused;

- (void)captureStillImage:(id)value;

- (void)cancel:(id)unused;

- (void)setUseLED:(NSNumber *)value;

- (NSNumber *)useLED;

- (void)setAllowRotation:(NSNumber *)value;

- (void)setUseFrontCamera:(NSNumber *)value;

- (NSNumber *)useFrontCamera;

@end
