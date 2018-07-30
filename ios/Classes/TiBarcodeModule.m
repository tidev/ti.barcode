/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiApp.h"
#import "LayoutConstraint.h"
#import "TiOverlayView.h"

@implementation TiBarcodeModule

#pragma mark Internal

-(id)moduleGUID
{
  return @"fe2e658e-0eaf-44a6-b6d1-c074d6b986a3";
}

-(NSString*)moduleId
{
  return @"ti.barcode";
}

#pragma mark Lifecycle

-(void)startup
{
	[super startup];

	NSLog(@"[DEBUG] %@ loaded",self);
    
    [self initialize];
}

- (void)initialize
{
    selectedCamera = MTBCameraBack;
    selectedLEDMode = MTBTorchModeOff;
}

#pragma mark Public API's

- (id)canShow:(id)unused
{
    return NUMBOOL([MTBBarcodeScanner cameraIsPresent] && ![MTBBarcodeScanner scanningIsProhibited]);
}

- (void)capture:(id)args
{
    ENSURE_UI_THREAD(capture, args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    BOOL keepOpen = [TiUtils boolValue:[args objectForKey:@"keepOpen"] def:NO];
    BOOL animate = [TiUtils boolValue:[args objectForKey:@"animate"] def:YES];
    BOOL showCancel = [TiUtils boolValue:@"showCancel" properties:args def:YES];
    BOOL showRectangle = [TiUtils boolValue:@"showRectangle" properties:args def:YES];
    NSString* displayedMessage = [TiUtils stringValue:[self valueForUndefinedKey:@"displayedMessage"]];

    NSMutableArray *acceptedFormats = [NSMutableArray arrayWithArray:[args objectForKey:@"acceptedFormats"]];
    TiViewProxy *overlayProxy = [args objectForKey:@"overlay"];
  
    if (acceptedFormats.count != 0) {
      if ([acceptedFormats containsObject:@-1]) {
        NSLog(@"[WARN] The code-format FORMAT_NONE is deprecated. Use an empty array instead or don't specify formats.");
        [acceptedFormats removeObject:@-1];
      }
    } else {
      [acceptedFormats addObjectsFromArray:@[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode]];
    }
  
    NSError *error = nil;
    NSError *cameraError = nil;
    UIView *overlayView = nil;
    if (overlayProxy != nil) {
      overlayView = [self prepareOverlayWithProxy:overlayProxy];
    }
  barcodeViewController = [[TiBarcodeViewController alloc] initWithObjectTypes:acceptedFormats delegate:self showCancel:showCancel showRectangle:showRectangle withOverlay:overlayView];
    [[barcodeViewController scanner] setCamera:selectedCamera ?: MTBCameraBack error:&cameraError];
  
  displayedMessage = @"testing";
  if (displayedMessage != nil) {
    [[barcodeViewController overlayView] setDisplayMessage: displayedMessage];
  }
    if (cameraError) {
        [self fireEvent:@"error" withObject:@{
            @"message": [cameraError localizedDescription] ?: @"Unknown error occurred."
        }];
    }
  
    [barcodeViewController setShouldAutorotate:allowRotation];
    [[barcodeViewController scanner] setTorchMode:MTBTorchModeOff];
    
    [[barcodeViewController scanner] startScanningWithResultBlock:^(NSArray *codes) {
        if (!codes || [codes count] == 0) {
            return;
        }
        
        [self fireEvent:@"success" withObject:@{
            @"result": [(AVMetadataMachineReadableCodeObject*)[codes firstObject] stringValue],
            @"corners": [(AVMetadataMachineReadableCodeObject *)[codes firstObject] corners]
        }];
        
        if (!keepOpen) {
            [self closeScanner];
        }
    } error:&error];
    
    if (error) {
        [self fireEvent:@"error" withObject:@{
            @"message": [error localizedDescription] ?: @"Unknown error occurred."
        }];
        
        if (!keepOpen) {
            [self closeScanner];
        }
    }
  
    [[[[TiApp app] controller] topPresentedController] presentViewController:barcodeViewController animated:animate completion:^{
        [[barcodeViewController scanner] setTorchMode:selectedLEDMode ?: MTBTorchModeOff];
    }];
}

- (void)freezeCapture:(id)unused
{
    ENSURE_UI_THREAD(freezeCapture, unused);
    [[barcodeViewController scanner] freezeCapture];
}

- (void)unfreezeCapture:(id)unused
{
    ENSURE_UI_THREAD(unfreezeCapture, unused);
    [[barcodeViewController scanner] unfreezeCapture];
}

- (void)captureStillImage:(id)value
{
    ENSURE_UI_THREAD(captureStillImage, value);
    ENSURE_SINGLE_ARG(value, KrollCallback);
    
    [[barcodeViewController scanner] captureStillImage:^(UIImage *image, NSError *error) {
        TiBlob *blob = [[TiBlob alloc] _initWithPageContext:[self pageContext]];
        [blob setImage:image];
        [blob setMimeType:@"image/png" type:TiBlobTypeImage];
        
        NSDictionary *event = [NSDictionary dictionaryWithObject:blob forKey:@"image"];
        [self _fireEventToListener:@"blob" withObject:event listener:(KrollCallback *)value thisObject:nil];
    }];
}

- (void)cancel:(id)unused
{
    ENSURE_UI_THREAD(cancel, unused);
    
    [self closeScanner];
    [self fireEvent:@"cancel" withObject:nil];
}

- (void)setUseLED:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [self replaceValue:value forKey:@"useLED" notification:NO];

    selectedLEDMode = [TiUtils boolValue:value def:YES] ? MTBTorchModeOn : MTBTorchModeOff;
    
    if (barcodeViewController) {
        [[barcodeViewController scanner] setTorchMode:selectedLEDMode];
    }
}

- (id)useLED
{
    return NUMBOOL(selectedLEDMode == MTBTorchModeOn);
}

- (void)setAllowRotation:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [self replaceValue:value forKey:@"allowRotation" notification:NO];

    allowRotation = [TiUtils boolValue:value def:NO];
}

- (void)setUseFrontCamera:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [self replaceValue:value forKey:@"useFrontCamera" notification:NO];
    
    selectedCamera = [TiUtils boolValue:value def:YES] ? MTBCameraFront : MTBCameraBack;
    NSError *cameraError;
  
    if (barcodeViewController) {
        [[barcodeViewController scanner] setCamera:selectedCamera error:&cameraError];
      
        if (cameraError) {
            [self fireEvent:@"error" withObject:@{
                @"message": [cameraError localizedDescription] ?: @"Unknown error occurred."
            }];
        }
    }
}

- (id)useFrontCamera
{
    return NUMBOOL(selectedCamera == MTBCameraFront);
}

-(id)parse:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);
 
  id blob = [args valueForKey:@"image"];
  ENSURE_TYPE(blob, TiBlob);
  
  UIImage *image = [(TiBlob*)blob image];
  CIImage *ciImage = [[CIImage alloc] initWithImage:image];
  CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow}];
  NSArray<CIFeature *> *features = [detector featuresInImage:ciImage];
  NSMutableString *result = [[NSMutableString alloc] init];
  for (CIFeature *feature in features) {
    if ([feature.type isEqualToString:CIFeatureTypeQRCode]) {
      [result appendString:[(CIQRCodeFeature *)feature messageString]];
    }
  }
  if([result length] > 0) {
    [self fireEvent:@"success" withObject:@{
                                            @"result": result
                                            }];
  } else {
    [self fireEvent:@"error" withObject:@{
                                          @"message": @"Unknown error occurred."
                                          }];
  }
  
  return NUMBOOL(true);
}

#pragma mark Internal

- (UIView *)prepareOverlayWithProxy:(TiViewProxy *)overlayProxy
{
    [overlayProxy windowWillOpen];
    
    CGSize size = [overlayProxy view].bounds.size;
    
#ifndef TI_USE_AUTOLAYOUT
    ApplyConstraintToViewWithBounds([overlayProxy layoutProperties], (TiUIView *)[overlayProxy view], [[UIScreen mainScreen] bounds]);
#else
  CGSize s = [[overlayProxy view] sizeThatFits:CGSizeMake(MAXFLOAT,MAXFLOAT)];
  CGFloat width = s.width;
  CGFloat height = s.height;
  
  if (width > 0 && height > 0) {
    size = CGSizeMake(width, height);
  }
  
  if (CGSizeEqualToSize(size, CGSizeZero) || width==0 || height == 0) {
    size = [UIScreen mainScreen].bounds.size;
  }
  
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  [TiUtils setView:[overlayProxy view] positionRect:rect];
  [overlayProxy layoutChildren:NO];
#endif
    
    return [overlayProxy view];
}

- (void)closeScanner
{
    if (!barcodeViewController) {
        NSLog(@"[ERROR] Trying to dismiss a scanner that hasn't been created, yet. Try again, Marty!");
        return;
    }
    if ([[barcodeViewController scanner] isScanning]) {
        [[barcodeViewController scanner] stopScanning];
    }
    
    [barcodeViewController setScanner:nil];
    [[[[barcodeViewController view] subviews] objectAtIndex:0] removeFromSuperview];
    [barcodeViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Constants


MAKE_SYSTEM_PROP(FORMAT_NONE, -1); // Deprecated, don't specify types
MAKE_SYSTEM_PROP(FORMAT_QR_CODE, AVMetadataObjectTypeQRCode);
MAKE_SYSTEM_PROP(FORMAT_DATA_MATRIX, AVMetadataObjectTypeDataMatrixCode);
MAKE_SYSTEM_PROP(FORMAT_UPC_E, AVMetadataObjectTypeUPCECode);
MAKE_SYSTEM_PROP(FORMAT_UPC_A, AVMetadataObjectTypeEAN13Code); // Sub-set
MAKE_SYSTEM_PROP(FORMAT_EAN_8 ,AVMetadataObjectTypeEAN8Code);
MAKE_SYSTEM_PROP(FORMAT_EAN_13, AVMetadataObjectTypeEAN13Code);
MAKE_SYSTEM_PROP(FORMAT_CODE_128, AVMetadataObjectTypeCode128Code);
MAKE_SYSTEM_PROP(FORMAT_CODE_39, AVMetadataObjectTypeCode39Code);
MAKE_SYSTEM_PROP(FORMAT_CODE_93, AVMetadataObjectTypeCode93Code); // New!
MAKE_SYSTEM_PROP(FORMAT_CODE_39_MOD_43, AVMetadataObjectTypeCode39Mod43Code); // New!
MAKE_SYSTEM_PROP(FORMAT_ITF, AVMetadataObjectTypeITF14Code);
MAKE_SYSTEM_PROP(FORMAT_PDF_417, AVMetadataObjectTypePDF417Code); // New!
MAKE_SYSTEM_PROP(FORMAT_AZTEC, AVMetadataObjectTypeAztecCode); // New!
MAKE_SYSTEM_PROP(FORMAT_FACE, AVMetadataObjectTypeFace); // New!
MAKE_SYSTEM_PROP(FORMAT_INTERLEAVED_2_OF_5, AVMetadataObjectTypeInterleaved2of5Code); // New!

#pragma mark TiOverlayViewDelegate

- (void)cancelled {
  [self closeScanner];
}

@end
