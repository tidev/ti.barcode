/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeViewController.h"
#import "TiModule.h"
#import <ZXingObjC/ZXingObjC.h>

@class TiOverlayView;
@class TiViewProxy;

@interface TiBarcodeModule : TiModule <TiOverlayViewDelegate, ZXCaptureDelegate> {
  @private
  TiBarcodeViewController *_barcodeViewController;
  BOOL _useFrontCamera;
  BOOL _useLED;
  NSString *_displayedMessage;
  TiViewProxy *_overlayViewProxy;
  BOOL keepOpen;
  ZXCapture *zxCapture;
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
