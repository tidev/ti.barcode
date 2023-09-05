/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiBarcodeModule.h"
#import "LayoutConstraint.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiBlob.h"
#import "TiBuffer.h"
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

- (NSString *)apiName
{
  return @"Ti.Barcode";
}

#pragma mark Lifecycle

- (void)startup
{
  [super startup];
}

- (id)_initWithPageContext:(id<TiEvaluator>)context
{
  if (self = [super _initWithPageContext:context]) {
    _useFrontCamera = NO;
    _useLED = NO;
  }

  return self;
}

#pragma mark Public API's

- (NSNumber *)canShow:(id)unused
{
  // TO DO: Remove
  return NUMBOOL(YES);
}

- (void)capture:(id)args
{
  ENSURE_UI_THREAD(capture, args);
  ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);

  keepOpen = [TiUtils boolValue:[args objectForKey:@"keepOpen"] def:NO];
  BOOL animate = [TiUtils boolValue:[args objectForKey:@"animate"] def:YES];
  BOOL showCancel = [TiUtils boolValue:@"showCancel" properties:args def:YES];
  BOOL showRectangle = [TiUtils boolValue:@"showRectangle" properties:args def:YES];
  BOOL preventRotation = [TiUtils boolValue:@"preventRotation" properties:args def:NO];

  _overlayViewProxy = [args objectForKey:@"overlay"];

  NSError *error = nil;
  NSError *cameraError = nil;
  UIView *overlayView = nil;
  if (_overlayViewProxy != nil) {
    [self rememberProxy:_overlayViewProxy];
    overlayView = [self prepareOverlayWithProxy:_overlayViewProxy];
  }
  _barcodeViewController = [[TiBarcodeViewController alloc] initWithDelegate:self showCancel:showCancel showRectangle:showRectangle withOverlay:overlayView preventRotation:preventRotation];

  _barcodeViewController.capture.camera = _useFrontCamera ? _barcodeViewController.capture.front : _barcodeViewController.capture.back;
  _barcodeViewController.capture.delegate = self;
    
    
  ZXDecodeHints *hints = [self generateHints:args];
  _barcodeViewController.capture.hints = hints;

  if (_displayedMessage != nil) {
    [[_barcodeViewController overlayView] setDisplayMessage:_displayedMessage];
  }
  if (cameraError) {
    [self fireEvent:@"error"
         withObject:@{
           @"message" : [cameraError localizedDescription] ?: @"Unknown error occurred."
         }];
  }

  if (error) {
    [self fireEvent:@"error"
         withObject:@{
           @"message" : [error localizedDescription] ?: @"Unknown error occurred."
         }];

    if (!keepOpen) {
      [self closeScanner];
    }
  }
#if TARGET_OS_MACCATALYST
    _barcodeViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [[[[TiApp app] controller] topPresentedController] presentViewController:_barcodeViewController
                                                                    animated:animate
                                                                  completion:^{
        self->_barcodeViewController.capture.torch = self->_useLED;
                                                                  }];
#else
    _barcodeViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [[[[TiApp app] controller] topPresentedController] presentViewController:_barcodeViewController
                                                                    animated:animate
                                                                  completion:^{
        self->_barcodeViewController.capture.torch = self->_useLED;
                                                                  }];
#endif
}

- (void)cancel:(id)unused
{
  ENSURE_UI_THREAD(cancel, unused);

  [self closeScanner];
  [self fireEvent:@"cancel" withObject:nil];
}

- (void)setUseLED:(NSNumber *)value
{
  ENSURE_TYPE(value, NSNumber);
  [self replaceValue:value forKey:@"useLED" notification:NO];

  _useLED = [TiUtils boolValue:value def:NO];
  if (_barcodeViewController != nil) {
    _barcodeViewController.capture.torch = _useLED;
  }
}

- (NSNumber *)useLED
{
  return NUMBOOL(_barcodeViewController.capture.torch);
}

- (void)setDisplayedMessage:(NSString *)message
{
  _displayedMessage = message;
}

- (void)setUseFrontCamera:(NSNumber *)value
{
  ENSURE_TYPE(value, NSNumber);
  [self replaceValue:value forKey:@"useFrontCamera" notification:NO];

  _useFrontCamera = [TiUtils boolValue:value def:YES];

  if (_barcodeViewController != nil) {
    _barcodeViewController.capture.camera = _useFrontCamera ? _barcodeViewController.capture.front : _barcodeViewController.capture.back;
  }
}

- (NSNumber *)useFrontCamera
{
  return NUMBOOL(_useFrontCamera);
}

- (NSNumber *)parse:(id)args
{
  ENSURE_SINGLE_ARG(args, NSDictionary);

  TiBlob *blob = [args valueForKey:@"image"];
  ENSURE_TYPE(blob, TiBlob);

  UIImage *image = [blob image];
  CGImageRef imageRef = [image CGImage];

  ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageRef];
  ZXHybridBinarizer *binarizer = [ZXHybridBinarizer binarizerWithSource:source];
  ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:binarizer];
  ZXDecodeHints *hints = [self generateHints:args];
  ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];

  NSError *error;

  ZXResult *result = [reader decode:bitmap hints:hints error:&error];
  if (!error && result) {
    [self handleSuccessResult:result.text withFormat:result.barcodeFormat withBytes:result.rawBytes];
  } else {
    [self fireEvent:@"error" withObject:@{ @"message" : @"Scan Failed", @"exception" : error.localizedDescription }];
    return NUMBOOL(NO);
  }
  return NUMBOOL(YES);
}

#pragma mark Internal
- (ZXDecodeHints *)generateHints:(NSDictionary *)args
{
  ZXDecodeHints *hints = [ZXDecodeHints hints];
  hints.assumeCode39CheckDigit = [TiUtils boolValue:@"assumeCode39CheckDigit" properties:args def:NO];
  hints.assumeGS1 = [TiUtils boolValue:@"assumeGS1" properties:args def:NO];
  hints.pureBarcode = [TiUtils boolValue:@"pureBarcode" properties:args def:NO];
  hints.returnCodaBarStartEnd = [TiUtils boolValue:@"returnCodabarStartEnd" properties:args def:NO];
  hints.tryHarder = [TiUtils boolValue:@"tryHarder" properties:args def:NO];

  NSArray *allowedLengths;
  ENSURE_ARG_OR_NIL_FOR_KEY(allowedLengths, args, @"allowedLengths", NSArray);
  if (allowedLengths) {
    hints.allowedLengths = allowedLengths;
  }

  NSArray *allowedEANExtensions;
  ENSURE_ARG_OR_NIL_FOR_KEY(allowedEANExtensions, args, @"allowedEANExtensions", NSArray);
  if (allowedEANExtensions) {
    NSUInteger length = [allowedEANExtensions count];
    ZXIntArray *extensions = [[ZXIntArray alloc] initWithLength:length];
    for (NSUInteger i = 0; i < length; i++) {
      NSNumber *extension = [allowedEANExtensions objectAtIndex:i];
      int32_t val = [extension intValue];
      extensions.array[i] = val;
    }
    hints.allowedEANExtensions = extensions;
  }

  NSString *characterSet;
  ENSURE_ARG_OR_NIL_FOR_KEY(characterSet, args, @"characterSet", NSString);
  if (characterSet) {
    NSStringEncoding encoding = [TiUtils charsetToEncoding:characterSet];
    hints.encoding = encoding;
  }

  NSMutableArray *acceptedFormats = [args objectForKey:@"acceptedFormats"];
  if (acceptedFormats.count != 0) {
    if ([acceptedFormats containsObject:@"-1"]) {
      NSLog(@"[WARN] The code-format FORMAT_NONE is deprecated. Use an empty array instead or don't specify formats.");
      [acceptedFormats removeObject:@"-1"];
    }
  }
  for (id format in acceptedFormats) {
    [hints addPossibleFormat:format];
  }

  return hints;
}

- (UIView *)prepareOverlayWithProxy:(TiViewProxy *)overlayProxy
{
  [overlayProxy windowWillOpen];

  CGSize size = [overlayProxy view].bounds.size;

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

  return [overlayProxy view];
}

- (void)closeScanner
{
  if (_barcodeViewController == nil) {
    NSLog(@"[ERROR] Trying to dismiss a scanner that hasn't been created, yet. Try again, Marty!");
    return;
  }
  _barcodeViewController.capture.delegate = nil;

  [_barcodeViewController.capture stop];

  [self forgetProxy:_overlayViewProxy];

  [_barcodeViewController dismissViewControllerAnimated:YES
                                             completion:^{
                                             }];
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
    NSString *value = [token substringFromIndex:range.location + 1];
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

- (void)parseSuccessResult:(NSString *)result withFormat:(ZXBarcodeFormat)format withBytes:(ZXByteArray *)bytes
{
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
  [event setObject:[NSNumber numberWithInteger:format] forKey:@"format"];

  TiBuffer *buffer = [[TiBuffer alloc] _initWithPageContext:[self executionContext]];
  if (bytes) {
    [buffer setData:[NSMutableData dataWithBytes:bytes.array length:bytes.length]];
  } else {
    [buffer setData:[NSMutableData dataWithCapacity:0]];
  }
  [event setObject:buffer forKey:@"bytes"];

  [self fireEvent:@"success" withObject:event];
}

- (void)handleSuccessResult:(NSString *)result withFormat:(ZXBarcodeFormat)format withBytes:(ZXByteArray *)bytes
{
  @try {
    [self parseSuccessResult:result withFormat:format withBytes:bytes];
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

MAKE_SYSTEM_PROP(FORMAT_NONE, -1); // Deprecated, don't specify types
MAKE_SYSTEM_PROP(FORMAT_AZTEC, kBarcodeFormatAztec);
MAKE_SYSTEM_PROP(FORMAT_CODABAR, kBarcodeFormatCodabar);
MAKE_SYSTEM_PROP(FORMAT_CODE_39, kBarcodeFormatCode39);
MAKE_SYSTEM_PROP(FORMAT_CODE_39_MOD_43, kBarcodeFormatCode39); // TODO: Remove in next release, same as CODE_39
MAKE_SYSTEM_PROP(FORMAT_CODE_93, kBarcodeFormatCode93);
MAKE_SYSTEM_PROP(FORMAT_CODE_128, kBarcodeFormatCode128);
MAKE_SYSTEM_PROP(FORMAT_DATA_MATRIX, kBarcodeFormatDataMatrix);
MAKE_SYSTEM_PROP(FORMAT_EAN_8, kBarcodeFormatEan8);
MAKE_SYSTEM_PROP(FORMAT_EAN_13, kBarcodeFormatEan13);
MAKE_SYSTEM_PROP(FORMAT_ITF, kBarcodeFormatITF);
MAKE_SYSTEM_PROP(FORMAT_INTERLEAVED_2_OF_5, kBarcodeFormatITF); // TODO: Remove in next release, same as ITF
MAKE_SYSTEM_PROP(FORMAT_MAXICODE, kBarcodeFormatMaxiCode);
MAKE_SYSTEM_PROP(FORMAT_PDF_417, kBarcodeFormatPDF417);
MAKE_SYSTEM_PROP(FORMAT_QR_CODE, kBarcodeFormatQRCode);
MAKE_SYSTEM_PROP(FORMAT_RSS_14, kBarcodeFormatRSS14);
MAKE_SYSTEM_PROP(FORMAT_RSS_EXPANDED, kBarcodeFormatRSSExpanded);
MAKE_SYSTEM_PROP(FORMAT_UPC_A, kBarcodeFormatUPCA);
MAKE_SYSTEM_PROP(FORMAT_UPC_E, kBarcodeFormatUPCE);
// MAKE_SYSTEM_PROP(FORMAT_UPCEAN_EXTENSION, kBarcodeFormatUPCEANExtension); // extension, not a stand-alone

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

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result
{
  if (!result)
    return;

  NSLog(result.text);

  [self handleSuccessResult:result.text withFormat:result.barcodeFormat withBytes:result.rawBytes];

  if (!keepOpen) {
    [self closeScanner];
  }
}

@end
