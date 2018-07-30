/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */


#import "TiBarcodeViewController.h"
#import "MTBBarcodeScanner.h"
#import "TiApp.h"
#import "TiOverlayView.h"

@implementation TiBarcodeViewController

- (instancetype)initWithObjectTypes:(NSArray *)objectTypes
           delegate:(id<TiOverlayViewDelegate>)delegate
            showCancel:(BOOL)shouldShowCancel
         showRectangle:(BOOL)shouldShowRectangle
           withOverlay:(UIView*)overlay {
  self = [super init];
  if (self) {
    _scanner = [[MTBBarcodeScanner alloc] initWithMetadataObjectTypes:objectTypes
                                                          previewView:[self view]];
    _shouldAutorotate = NO;
    _overlayView = [[TiOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                         showCancel:true
                                                      showRectangle:true
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

- (void)viewDidAppear:(BOOL)animated
{
  [[self view] addSubview:_overlayView];
}

- (BOOL)shouldAutorotate
{
    return _shouldAutorotate;
}

- (TiOverlayView *)overlayView
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
