/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiOverlayView.h"
#import <UIKit/UIKit.h>

@class MTBBarcodeScanner;
@class TiOverlayView;

#if !TARGET_IPHONE_SIMULATOR
#define HAS_AVFF 1
#endif

@interface TiBarcodeViewController : UIViewController {
  @private
  TiOverlayView *_overlayView;
  BOOL _showRectangle;
  BOOL _preventRotation;
}

- (TiOverlayView *)overlayView;

- (id)initWithObjectTypes:(NSArray *)objectTypes
                 delegate:(id<TiOverlayViewDelegate>)delegate
               showCancel:(BOOL)shouldShowCancel
            showRectangle:(BOOL)shouldShowRectangle
              withOverlay:(UIView *)overlay
          preventRotation:(BOOL)preventRotation;

@property (nonatomic, strong) MTBBarcodeScanner *scanner;

@end
