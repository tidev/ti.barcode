/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import <UIKit/UIKit.h>
#import "TiOverlayView.h"

@class MTBBarcodeScanner;
@class TiOverlayView;

@interface TiBarcodeViewController : UIViewController {
  @private
  TiOverlayView *_overlayView;
  BOOL _showRectangle;
}

- (TiOverlayView *)overlayView;

- (id)initWithObjectTypes:(NSArray *)objectTypes
           delegate:(id<TiOverlayViewDelegate>)delegate
            showCancel:(BOOL)shouldShowCancel
         showRectangle:(BOOL)shouldShowRectangle
           withOverlay:(UIView *)overlay;

@property(nonatomic, strong) MTBBarcodeScanner *scanner;

@property(nonatomic, assign) BOOL shouldAutorotate;

@end
