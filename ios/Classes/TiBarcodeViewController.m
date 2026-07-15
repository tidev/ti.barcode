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
  // Raw capture buffer size, in sensor (landscape) orientation.
  CGFloat videoWidth;
  CGFloat videoHeight;
  if ([self.capture.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
    videoWidth = 1920;
    videoHeight = 1080;
  } else {
    videoWidth = 1280;
    videoHeight = 720;
  }

  BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
  CGSize layerSize = self.capture.layer.frame.size;

  // Video dimensions as displayed on screen (swapped in portrait).
  CGFloat displayedVideoWidth = isPortrait ? videoHeight : videoWidth;
  CGFloat displayedVideoHeight = isPortrait ? videoWidth : videoHeight;

  // The preview layer uses AVLayerVideoGravityResizeAspectFill: the video is
  // scaled up until it fills the layer and the overflow is center-cropped
  // off screen. Unproject the on-screen crop rect into video pixels,
  // accounting for that hidden overflow — otherwise the decoded region
  // drifts away from the drawn rectangle (badly so on 4:3 screens like iPads).
  CGFloat fillScale = MAX(layerSize.width / displayedVideoWidth, layerSize.height / displayedVideoHeight);
  CGFloat overflowX = (displayedVideoWidth * fillScale - layerSize.width) / 2;
  CGFloat overflowY = (displayedVideoHeight * fillScale - layerSize.height) / 2;

  CGRect cropRect = _overlayView.cropRect;
  CGFloat videoX = (cropRect.origin.x + overflowX) / fillScale;
  CGFloat videoY = (cropRect.origin.y + overflowY) / fillScale;
  CGFloat videoRectWidth = cropRect.size.width / fillScale;
  CGFloat videoRectHeight = cropRect.size.height / fillScale;

  // ZXCapture crops the buffer BEFORE rotating it (ZXCapture decodeImage:),
  // so express the rect in sensor (landscape) coordinates.
  // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
  CGRect scanRect;
  if (isPortrait) {
    scanRect = CGRectMake(videoY,
                          displayedVideoWidth - videoRectWidth - videoX,
                          videoRectHeight,
                          videoRectWidth);
  } else {
    scanRect = CGRectMake(videoX, videoY, videoRectWidth, videoRectHeight);
  }
  self.capture.scanRect = scanRect;
}

@end
