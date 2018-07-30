/**
 * Ti.BarcodeScanner
 * Copyright (c) 2017-present by Hans Knöchel. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import <UIKit/UIKit.h>
#import "OverlayView1.h"

@class MTBBarcodeScanner;
@class OverlayView1;

@interface TiBarcodeViewController : UIViewController {
  @private
  OverlayView1 *_overlayView;
  BOOL showRectangle;
}

//- (instancetype)initWithObjectTypes:(NSArray *)objectTypes;

- (OverlayView1 *)overlayView;

- (id)initWithObjectTypes:(NSArray *)objectTypes
           cancelDelegate:(id<CancelDelegate>)delegate
            showCancel:(BOOL)shouldShowCancel
         showRectangle:(BOOL)shouldShowRectangle
           withOverlay:(UIView*)overlay;

@property(nonatomic, strong) MTBBarcodeScanner *scanner;

@property(nonatomic, assign) BOOL shouldAutorotate;

@end
