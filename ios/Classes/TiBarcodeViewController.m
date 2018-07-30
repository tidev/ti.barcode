/**
 * Ti.BarcodeScanner
 * Copyright (c) 2017-present by Hans Knöchel. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeViewController.h"
#import "MTBBarcodeScanner.h"
#import "TiApp.h"
#import "OverlayView1.h"

@implementation TiBarcodeViewController

- (instancetype)initWithObjectTypes:(NSArray *)objectTypes
           cancelDelegate:(id<CancelDelegate>)delegate
            showCancel:(BOOL)shouldShowCancel
         showRectangle:(BOOL)shouldShowRectangle
           withOverlay:(UIView*)overlay {
  self = [super init];
  if (self) {
    _scanner = [[MTBBarcodeScanner alloc] initWithMetadataObjectTypes:objectTypes
                                                          previewView:[self view]];
    _shouldAutorotate = NO;
    _overlayView = [[OverlayView1 alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                         cancelEnabled:true
                                                      rectangleEnabled:true
                                                           withOverlay:nil];
    showRectangle = true;//shouldShowRectangle;
    _overlayView.delegate = delegate;
    
    if (showRectangle) {
      CGRect rect = _overlayView.cropRect;
      [_scanner setDidStartScanningBlock:^(void) {
        [_scanner setScanRect:rect];
      }];
    }
  }
  return self;
}
/*
- (instancetype)initWithObjectTypes:(NSArray *)objectTypes
{
    if (self = [super init]) {
        _scanner = [[MTBBarcodeScanner alloc] initWithMetadataObjectTypes:objectTypes
                                                              previewView:[self view]];
        _shouldAutorotate = NO;
      OverlayView1 *theOverlayView = [[OverlayView1 alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                         cancelEnabled:true
                                                      rectangleEnabled:true
                                                              oneDMode:false
                                                           withOverlay:nil];
    }
    
    return self;
}
*/
- (void)viewDidAppear:(BOOL)animated
{
  [[self view] addSubview:_overlayView];
}

- (void)setOverlayView:(UIView *)view
{
  //_overlayView = view;
  [[self view] addSubview:_overlayView];
}

- (BOOL)shouldAutorotate
{
    return _shouldAutorotate;
}

- (OverlayView1 *)overlayView
{
  return _overlayView;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
  return [[[TiApp app] controller] preferredStatusBarStyle];
}

// MOD-2190: Fix the orientation by using the parent one.
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return [[[[TiApp app] controller] topContainerController] preferredInterfaceOrientationForPresentation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  CGRect frame = CGRectMake(_overlayView.frame.origin.x, _overlayView.frame.origin.y, size.width, size.height);
  [_overlayView updateViewsWithFrame:frame];
  if (showRectangle) {
    CGRect rect = _overlayView.cropRect;
    [_scanner setScanRect:rect];
  }
}

@end
