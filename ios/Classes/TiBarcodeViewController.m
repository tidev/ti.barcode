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


- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
                                                         showCancel:shouldShowCancel
                                                      showRectangle:shouldShowRectangle
                                                           withOverlay:overlay];
    showRectangle = shouldShowRectangle;
    _overlayView.delegate = delegate;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceRotation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    if (showRectangle) {
      CGRect rect = _overlayView.cropRect;
      __weak TiBarcodeViewController *weakSelf = self;
      [_scanner setDidStartScanningBlock:^(void) {
        [[weakSelf scanner] setScanRect:rect];
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return [[[[TiApp app] controller] topContainerController] preferredInterfaceOrientationForPresentation];
}

- (void)handleDeviceRotation:(NSNotification *)notification
{
    if (showRectangle) {
      CGRect rect = _overlayView.cropRect;
      [_scanner setScanRect:rect];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [_overlayView updateViewsWithFrame:CGRectMake(_overlayView.frame.origin.x, _overlayView.frame.origin.y, size.width, size.height)];
}

@end
