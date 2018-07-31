/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeModule.h"
#import "LayoutConstraint.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiOverlayView.h"
#import "TiUtils.h"
#import "TiViewProxy.h"

@implementation TiBarcodeModule

#pragma mark Internal

- (id)moduleGUID
{
  return @"fe2e658e-0eaf-44a6-b6d1-c074d6b986a3";
}

- (NSString *)moduleId
{
  return @"ti.barcode";
}

#pragma mark Lifecycle

- (void)startup
{
  [super startup];

  NSLog(@"[DEBUG] %@ loaded", self);

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
  NSString *displayedMessage = [TiUtils stringValue:[self valueForUndefinedKey:@"displayedMessage"]];

  NSMutableArray *acceptedFormats = [NSMutableArray arrayWithArray:[args objectForKey:@"acceptedFormats"]];
  TiViewProxy *overlayProxy = [args objectForKey:@"overlay"];

  if (acceptedFormats.count != 0) {
    if ([acceptedFormats containsObject:@"-1"]) {
      NSLog(@"[WARN] The code-format FORMAT_NONE is deprecated. Use an empty array instead or don't specify formats.");
      [acceptedFormats removeObject:@"-1"];
    }
  } else {
    [acceptedFormats addObjectsFromArray:@[ AVMetadataObjectTypeQRCode, AVMetadataObjectTypeDataMatrixCode, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeInterleaved2of5Code ]];
  }

  NSError *error = nil;
  NSError *cameraError = nil;
  UIView *overlayView = nil;
  if (overlayProxy != nil) {
    overlayView = [self prepareOverlayWithProxy:overlayProxy];
  }
  barcodeViewController = [[TiBarcodeViewController alloc] initWithObjectTypes:acceptedFormats delegate:self showCancel:showCancel showRectangle:showRectangle withOverlay:overlayView];
  [[barcodeViewController scanner] setCamera:selectedCamera ?: MTBCameraBack error:&cameraError];

  if (displayedMessage != nil) {
    [[barcodeViewController overlayView] setDisplayMessage:displayedMessage];
  }
  if (cameraError) {
    [self fireEvent:@"error"
         withObject:@{
           @"message" : [cameraError localizedDescription] ?: @"Unknown error occurred."
         }];
  }

  [barcodeViewController setShouldAutorotate:allowRotation];
  [[barcodeViewController scanner] setTorchMode:MTBTorchModeOff];

  [[barcodeViewController scanner] startScanningWithResultBlock:^(NSArray *codes) {
    if (!codes || [codes count] == 0) {
      return;
    }
    [self handleSuccessResult:[(AVMetadataMachineReadableCodeObject *)[codes firstObject] stringValue]];

    if (!keepOpen) {
      [self closeScanner];
    }
  }
                                                          error:&error];

  if (error) {
    [self fireEvent:@"error"
         withObject:@{
           @"message" : [error localizedDescription] ?: @"Unknown error occurred."
         }];

    if (!keepOpen) {
      [self closeScanner];
    }
  }

  [[[[TiApp app] controller] topPresentedController] presentViewController:barcodeViewController
                                                                  animated:animate
                                                                completion:^{
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
      [self fireEvent:@"error"
           withObject:@{
             @"message" : [cameraError localizedDescription] ?: @"Unknown error occurred."
           }];
    }
  }
}

- (id)useFrontCamera
{
  return NUMBOOL(selectedCamera == MTBCameraFront);
}

- (id)parse:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);

  id blob = [args valueForKey:@"image"];
  ENSURE_TYPE(blob, TiBlob);

  UIImage *image = [(TiBlob *)blob image];
  CIImage *ciImage = [[CIImage alloc] initWithImage:image];
  CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyLow }];
  NSArray<CIFeature *> *features = [detector featuresInImage:ciImage];
  NSMutableString *result = [[NSMutableString alloc] init];
  for (CIFeature *feature in features) {
    if ([feature.type isEqualToString:CIFeatureTypeQRCode]) {
      [result appendString:[(CIQRCodeFeature *)feature messageString]];
    }
  }
  if ([result length] > 0) {
    [self handleSuccessResult:result];
  } else {
    [self fireEvent:@"error"
         withObject:@{
           @"message" : @"Unknown error occurred."
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
  CGSize s = [[overlayProxy view] sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
  CGFloat width = s.width;
  CGFloat height = s.height;

  if (width > 0 && height > 0) {
    size = CGSizeMake(width, height);
  }

  if (CGSizeEqualToSize(size, CGSizeZero) || width == 0 || height == 0) {
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

#pragma mark Parsing Utility Methods

- (void)parseMeCard:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:7];
  NSArray *tokens = [payload componentsSeparatedByString:@";"];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSString *token in tokens) {
    NSRange range = [token rangeOfString:@":"];
    if (range.location == NSNotFound)
      continue;
    NSString *key = [token substringToIndex:range.location];
    if ([key isEqualToString:@""])
      continue;
    NSString *value = [token substringFromIndex:range.location + 1];
    if ([key isEqualToString:@"N"]) {
      key = @"NAME";
    }
    value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
    [data setObject:value forKey:[key lowercaseString]];
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseWifi:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:5];
  NSArray *tokens = [payload componentsSeparatedByString:@";"];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSString *token in tokens) {
    NSRange range = [token rangeOfString:@":"];
    if (range.location == NSNotFound)
      continue;
    NSString *key = [token substringToIndex:range.location];
    if ([key isEqualToString:@""])
      continue;
    NSString *value = [token substringFromIndex:range.location + 1];
    value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
    [data setObject:value forKey:[key lowercaseString]];
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseBookmark:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:6];
  NSArray *tokens = [payload componentsSeparatedByString:@";"];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSString *token in tokens) {
    NSRange range = [token rangeOfString:@":"];
    if (range.location == NSNotFound)
      continue;
    NSString *key = [token substringToIndex:range.location];
    if ([key isEqualToString:@""])
      continue;
    NSString *value = [token substringFromIndex:range.location + 1];
    value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
    [data setObject:value forKey:[key lowercaseString]];
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseGeolocation:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:4];
  NSArray *tokens = [payload componentsSeparatedByString:@","];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  @try {
    [data setObject:[tokens objectAtIndex:0] forKey:@"latitude"];
    [data setObject:[tokens objectAtIndex:1] forKey:@"longitude"];
  }
  @catch (NSException *e) {
    NSLog(@"[WARN] Not all parameters available for parsing geolocation");
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseMailto:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:7];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  [data setObject:payload forKey:@"email"];
  [event setObject:data forKey:@"data"];
}

- (void)parseTel:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:4];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  [data setObject:payload forKey:@"phonenumber"];
  [event setObject:data forKey:@"data"];
}

- (void)parseSms:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:4];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  [data setObject:payload forKey:@"phonenumber"];
  [event setObject:data forKey:@"data"];
}

- (void)parseSmsTo:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:6];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  NSRange range = [payload rangeOfString:@":"];
  if (range.location == NSNotFound) {
    [data setObject:payload forKey:@"phonenumber"];
  } else {
    [data setObject:[payload substringToIndex:range.location] forKey:@"phonenumber"];
    [data setObject:[payload substringFromIndex:range.location + 1] forKey:@"message"];
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseEmailto:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSString *payload = [content substringFromIndex:5];
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  NSArray *tokens = [payload componentsSeparatedByString:@":"];

  @try {
    if ([tokens count] >= 1)
      [data setObject:[tokens objectAtIndex:0] forKey:@"email"];
    if ([tokens count] >= 2)
      [data setObject:[tokens objectAtIndex:1] forKey:@"subject"];
    if ([tokens count] >= 3)
      [data setObject:[tokens objectAtIndex:2] forKey:@"message"];
  }
  @catch (NSException *e) {
    NSLog(@"[WARN] Not all parameters available for parsing E-Mail");
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseVcard:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSString *token in [content componentsSeparatedByString:@"\n"]) {
    if ([token hasPrefix:@"BEGIN:VCARD"])
      continue;
    if ([token hasPrefix:@"END:VCARD"])
      break;
    NSRange range = [token rangeOfString:@":"];
    if (range.location == NSNotFound)
      continue;
    NSString *key = [token substringToIndex:range.location];
    NSString *value = [token substringFromIndex:range.location + 1];
    if ([key isEqualToString:@"N"]) {
      key = @"NAME";
    }
    value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
    [data setObject:value forKey:[key lowercaseString]];
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseVevent:(NSMutableDictionary *)event withString:(NSString *)content
{
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSString *token in [content componentsSeparatedByString:@"\n"]) {
    if ([token hasPrefix:@"BEGIN:VEVENT"])
      continue;
    if ([token hasPrefix:@"END:VEVENT"])
      break;
    NSRange range = [token rangeOfString:@":"];
    if (range.location == NSNotFound)
      continue;
    NSString *key = [token substringToIndex:range.location];
    id value = [token substringFromIndex:range.location + 1];
    if ([key isEqualToString:@"N"]) {
      key = @"NAME";
    }
    value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
    if (value != nil) {
      [data setObject:[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
               forKey:[key lowercaseString]];
    }
  }
  [event setObject:data forKey:@"data"];
}

- (void)parseSuccessResult:(NSString *)result
{
  NSLog(@"[DEBUG] Received barcode result = %@", result);

  NSMutableDictionary *event = [NSMutableDictionary dictionary];
  [event setObject:result forKey:@"result"];
  NSString *prefixCheck = [[result substringToIndex:MIN(20, [result length])] lowercaseString];
  if ([prefixCheck hasPrefix:@"http://"] || [prefixCheck hasPrefix:@"https://"]) {
    [event setObject:[self URL] forKey:@"contentType"];
  } else if ([prefixCheck hasPrefix:@"sms:"]) {
    [event setObject:[self SMS] forKey:@"contentType"];
    [self parseSms:event withString:result];
  } else if ([prefixCheck hasPrefix:@"smsto:"]) {
    [event setObject:[self SMS] forKey:@"contentType"];
    [self parseSmsTo:event withString:result];
  } else if ([prefixCheck hasPrefix:@"tel:"]) {
    [event setObject:[self TELEPHONE] forKey:@"contentType"];
    [self parseTel:event withString:result];
  } else if ([prefixCheck hasPrefix:@"begin:vevent"]) {
    [event setObject:[self CALENDAR] forKey:@"contentType"];
    [self parseVevent:event withString:result];
  } else if ([prefixCheck hasPrefix:@"mecard:"]) {
    [event setObject:[self CONTACT] forKey:@"contentType"];
    [self parseMeCard:event withString:result];
  } else if ([prefixCheck hasPrefix:@"begin:vcard"]) {
    [event setObject:[self CONTACT] forKey:@"contentType"];
    [self parseVcard:event withString:result];
  } else if ([prefixCheck hasPrefix:@"mailto:"]) {
    [event setObject:[self EMAIL] forKey:@"contentType"];
    [self parseMailto:event withString:result];
  } else if ([prefixCheck hasPrefix:@"smtp:"]) {
    [event setObject:[self EMAIL] forKey:@"contentType"];
    [self parseEmailto:event withString:result];
  } else if ([prefixCheck hasPrefix:@"geo:"]) {
    [event setObject:[self GEOLOCATION] forKey:@"contentType"];
    [self parseGeolocation:event withString:result];
  } else if ([prefixCheck hasPrefix:@"mebkm:"]) {
    [event setObject:[self BOOKMARK] forKey:@"contentType"];
    [self parseBookmark:event withString:result];
  } else if ([prefixCheck hasPrefix:@"wifi:"]) {
    [event setObject:[self WIFI] forKey:@"contentType"];
    [self parseWifi:event withString:result];
  } else {
    // anything else is assumed to be text
    [event setObject:[self TEXT] forKey:@"contentType"];
  }
  [self fireEvent:@"success" withObject:event];
}

- (void)handleSuccessResult:(NSString *)result
{
  @try {
    [self parseSuccessResult:result];
  }
  @catch (NSException *e) {
    [self fireEvent:@"error" withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[e reason], @"message", nil]];
  }
}

#pragma mark TiOverlayViewDelegate

- (void)cancelled
{
  [self closeScanner];
}

#pragma mark Constants

MAKE_SYSTEM_STR(FORMAT_NONE, @"-1"); // Deprecated, don't specify types
MAKE_SYSTEM_STR(FORMAT_QR_CODE, AVMetadataObjectTypeQRCode);
MAKE_SYSTEM_STR(FORMAT_DATA_MATRIX, AVMetadataObjectTypeDataMatrixCode);
MAKE_SYSTEM_STR(FORMAT_UPC_E, AVMetadataObjectTypeUPCECode);
MAKE_SYSTEM_STR(FORMAT_UPC_A, AVMetadataObjectTypeEAN13Code); // Sub-set
MAKE_SYSTEM_STR(FORMAT_EAN_8, AVMetadataObjectTypeEAN8Code);
MAKE_SYSTEM_STR(FORMAT_EAN_13, AVMetadataObjectTypeEAN13Code);
MAKE_SYSTEM_STR(FORMAT_CODE_128, AVMetadataObjectTypeCode128Code);
MAKE_SYSTEM_STR(FORMAT_CODE_39, AVMetadataObjectTypeCode39Code);
MAKE_SYSTEM_STR(FORMAT_CODE_93, AVMetadataObjectTypeCode93Code); // New!
MAKE_SYSTEM_STR(FORMAT_CODE_39_MOD_43, AVMetadataObjectTypeCode39Mod43Code); // New!
MAKE_SYSTEM_STR(FORMAT_ITF, AVMetadataObjectTypeITF14Code);
MAKE_SYSTEM_STR(FORMAT_PDF_417, AVMetadataObjectTypePDF417Code); // New!
MAKE_SYSTEM_STR(FORMAT_AZTEC, AVMetadataObjectTypeAztecCode); // New!
MAKE_SYSTEM_STR(FORMAT_FACE, AVMetadataObjectTypeFace); // New!
MAKE_SYSTEM_STR(FORMAT_INTERLEAVED_2_OF_5, AVMetadataObjectTypeInterleaved2of5Code); // New!

MAKE_SYSTEM_PROP(UNKNOWN, 0);
MAKE_SYSTEM_PROP(URL, 1);
MAKE_SYSTEM_PROP(SMS, 2);
MAKE_SYSTEM_PROP(TELEPHONE, 3);
MAKE_SYSTEM_PROP(TEXT, 4);
MAKE_SYSTEM_PROP(CALENDAR, 5);
MAKE_SYSTEM_PROP(GEOLOCATION, 6);
MAKE_SYSTEM_PROP(EMAIL, 7);
MAKE_SYSTEM_PROP(CONTACT, 8);
MAKE_SYSTEM_PROP(BOOKMARK, 9);
MAKE_SYSTEM_PROP(WIFI, 10);

@end
