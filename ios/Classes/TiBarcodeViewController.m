/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2020 by Axway, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeViewController.h"
#import "TiApp.h"
#import "TiOverlayView.h"

@implementation TiBarcodeViewController

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithDelegate:(id<TiOverlayViewDelegate>)delegate
                      showCancel:(BOOL)shouldShowCancel
                   showRectangle:(BOOL)shouldShowRectangle
                     withOverlay:(UIView *)overlay
                 preventRotation:(BOOL)preventRotation
{
  self = [super init];
  if (self) {

#if HAS_AVFF
    self.capture = [[ZXCapture alloc] init];
#endif
    _overlayView = [[TiOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                             showCancel:shouldShowCancel
                                          showRectangle:shouldShowRectangle
                                            withOverlay:overlay];
    _showRectangle = shouldShowRectangle;
    _overlayView.delegate = delegate;
    _preventRotation = preventRotation;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceRotation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    if (_showRectangle) {
      CGRect rect = _overlayView.cropRect;
    }
  }
  return self;
}

- (void)viewDidLoad
{
  self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
  [self.view.layer addSublayer:self.capture.layer];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [_overlayView updateViewsWithFrame:[UIScreen mainScreen].bounds];

  [[self view] addSubview:_overlayView];
  [[self view] bringSubviewToFront:_overlayView];
#if HAS_AVFF
  self.capture.layer.frame = _overlayView.frame;
#endif
  [self applyOrientation];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [_overlayView removeFromSuperview];
}

- (TiOverlayView *)overlayView
{
  return _overlayView;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return [[[TiApp app] controller] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
  return [[[TiApp app] controller] prefersStatusBarHidden];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return [[[[TiApp app] controller] topContainerController] preferredInterfaceOrientationForPresentation];
}

- (BOOL)shouldAutorotate
{
  [super shouldAutorotate];

  if (_preventRotation) {
    return NO;
  }

  return YES;
}

- (void)handleDeviceRotation:(NSNotification *)notification
{
  if (_showRectangle) {
    CGRect rect = _overlayView.cropRect;
  }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [_overlayView updateViewsWithFrame:CGRectMake(_overlayView.frame.origin.x, _overlayView.frame.origin.y, size.width, size.height)];
  [coordinator
      animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
      }
      completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applyOrientation];
      }];
}

#pragma mark - ZXCaptureDelegate Methods

#pragma mark - Private
- (void)applyOrientation
{
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  float scanRectRotation;
  float captureRotation;

  switch (orientation) {
  case UIInterfaceOrientationPortrait:
    captureRotation = 0;
    scanRectRotation = 90;
    break;
  case UIInterfaceOrientationLandscapeLeft:
    captureRotation = 90;
    scanRectRotation = 180;
    break;
  case UIInterfaceOrientationLandscapeRight:
    captureRotation = 270;
    scanRectRotation = 0;
    break;
  case UIInterfaceOrientationPortraitUpsideDown:
    captureRotation = 180;
    scanRectRotation = 270;
    break;
  default:
    captureRotation = 0;
    scanRectRotation = 90;
    break;
  }

  CGAffineTransform transform = CGAffineTransformMakeRotation((CGFloat)(captureRotation / 180 * M_PI));
  [self.capture setTransform:transform];
  [self.capture setRotation:scanRectRotation];
  self.capture.layer.frame = _overlayView.frame;
  if (_showRectangle) {
    [self applyRectOfInterest:orientation];
  }
}

- (void)applyRectOfInterest:(UIInterfaceOrientation)orientation
{
  CGFloat scaleVideoX, scaleVideoY;
  CGFloat videoSizeX, videoSizeY;
  CGRect transformedVideoRect = _overlayView.cropRect;
  if ([self.capture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
    videoSizeX = 1080;
    videoSizeY = 1920;
  } else {
    videoSizeX = 720;
    videoSizeY = 1280;
  }
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    scaleVideoX = self.capture.layer.frame.size.width / videoSizeX;
    scaleVideoY = self.capture.layer.frame.size.height / videoSizeY;

    // Convert CGPoint under portrait mode to map with orientation of image
    // because the image will be cropped before rotate
    // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
    CGFloat realX = transformedVideoRect.origin.y;
    CGFloat realY = self.capture.layer.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x;
    CGFloat realWidth = transformedVideoRect.size.height;
    CGFloat realHeight = transformedVideoRect.size.width;
    transformedVideoRect = CGRectMake(realX, realY, realWidth, realHeight);

  } else {
    scaleVideoX = self.capture.layer.frame.size.width / videoSizeY;
    scaleVideoY = self.capture.layer.frame.size.height / videoSizeX;
  }

  _captureSizeTransform = CGAffineTransformMakeScale(1.0 / scaleVideoX, 1.0 / scaleVideoY);
  self.capture.scanRect = CGRectApplyAffineTransform(transformedVideoRect, _captureSizeTransform);
}

@end
