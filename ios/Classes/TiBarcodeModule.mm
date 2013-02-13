/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

// Has to be an .mm file so that ZXing headers are found correctly
#import "TiBarcodeModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"
#import <DataMatrixReader.h>
#import <FormatReader.h>

#import <zxing/MultiFormatReader.h>
#import <zxing/oned/MultiFormatOneDReader.h>
#import <zxing/BarcodeFormat.h>

// The ZXing library provides support for a MultiFormatReader. However, it
// does not define an interface AND it does not provide support for the
// 'tryHarder' flag (because the current implementation only calls the
// _decode method which defaults to the DEFAULT_HINTS and does not allow
// the specification of the 'tryHarder' flag). The solution is to create
// our own customer multi-format reader class which defines its own
// hints value AND supports the specification of the 'tryHarder' flag.

@interface CustomMultiFormatReader : FormatReader {
}
-(id) init;
-(void) setTryHarder:(BOOL)enable;
-(void) setAcceptedFormats:(NSArray*)acceptedFormats;

@end

@implementation CustomMultiFormatReader

static zxing::DecodeHints decodeHints;

- (id)init {
	// Start with the default set of hints. We can always set these ourself,
	// but we might as well use the default set specified by ZXing so that
	// if the ZXing library is updated with new formats we do not need to
	// make any changes on our side.
	decodeHints = zxing::DecodeHints::DEFAULT_HINT;
	
	// NOTE: The ZXing library supports the DataMatrixReader format but
	// it is not defined as part of the default hints in DataHints.h. It
	// has been commented out in the current library implementation because
	// it has not been officially passed by QA. However, it does appear to
	// work sufficiently in testing. We can add support for the DataMatrixReader
	// format by adding it to the set of readers supported in the hints field. 
	//
	// If the DataMatrixReader is enabled in a future release of ZXing then
	// we can remove this call to add it. But, no harm is done if it is already
	// in the list.
	decodeHints.addFormat(zxing::BarcodeFormat_DATA_MATRIX);
	
	zxing::MultiFormatReader *reader = new zxing::MultiFormatReader();
	return [super initWithReader:reader];
}

- (void)setTryHarder:(BOOL)enable {
	// Setting the 'TryHarder' flag to true tells the ZXing library to
	// try both the original image and the image rotated 90 degrees.
	decodeHints.setTryHarder(enable);
}

- (void)setAcceptedFormats:(NSArray*)acceptedFormats {
    
    zxing::DecodeHints newHints = zxing::DecodeHints();
    newHints.setTryHarder(decodeHints.getTryHarder());
    
    for (id format in acceptedFormats) {
        newHints.addFormat((zxing::BarcodeFormat)[TiUtils intValue:format]);
    }
    
    decodeHints = newHints;
}

- (zxing::Ref<zxing::Result>)decode:(zxing::Ref<zxing::BinaryBitmap>)grayImage {
	return reader_->decode(grayImage, decodeHints);
}

- (zxing::Ref<zxing::Result>)decode:(zxing::Ref<zxing::BinaryBitmap>)grayImage andCallback:(zxing::Ref<zxing::ResultPointCallback>)callback
{
	zxing::DecodeHints hints = decodeHints;
    hints.setResultPointCallback(callback);
    return reader_->decode(grayImage, hints);
}

@end

@implementation TiBarcodeModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"fe2e658e-0eaf-44a6-b6d1-c074d6b986a3";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.barcode";
}

#pragma mark Cleanup and Lifecycle

-(void)_cleanup
{
	if (controller!=nil)
	{
        [self forgetSelf];
		controller.delegate = nil;
		// [MOD-232] Animation controlled by caller
		[controller dismissModalViewControllerAnimated:animate];
	}
	RELEASE_TO_NIL(controller);
}

-(void)_destroy
{
	[self _cleanup];
	[super _destroy];
}


#pragma Public APIs

-(id)useFrontCamera
{
    return NUMBOOL(useFrontCamera);
}

-(void)setUseFrontCamera:(id)arg
{
    bool val = [TiUtils boolValue:arg def:NO];
    useFrontCamera = val;
    
    if (controller != nil) {
        controller.useFrontCamera = useFrontCamera;
        [controller syncDeviceInput];
    }
}

-(void)setUseLED:(id)arg
{
    led = [TiUtils boolValue:arg def:NO];
    
    if (controller != nil) {
        [controller setTorch:led];
    }
}

-(id)useLED
{
    return NUMBOOL(led);
}

-(id)parse:(id)args
{
	ENSURE_SINGLE_ARG(args,NSDictionary);
    
    id blob = [args valueForKey:@"image"];
	ENSURE_TYPE(blob, TiBlob);
    UIImage* image = [blob image];
    
    bool tryHarder = [TiUtils boolValue:[self valueForUndefinedKey:@"allowRotation"] def:NO];
    id acceptedFormats = [args valueForKey:@"acceptedFormats"];
    
    CustomMultiFormatReader* multiFormatReader = [[CustomMultiFormatReader alloc] init];
	[multiFormatReader setTryHarder:tryHarder];
    if (acceptedFormats != nil) {
        ENSURE_ARRAY(acceptedFormats);
        [multiFormatReader setAcceptedFormats:acceptedFormats];
    }
    
    Decoder *d = [[Decoder alloc] init];
    d.keepOpen = keepOpen;
    d.readers = [NSSet setWithObject:multiFormatReader];
    d.delegate = self;
    
    bool retVal = [d decodeImage:image];
    
    [d release];
    
    return NUMBOOL(retVal);
}

-(void)capture:(id)args
{
	ENSURE_UI_THREAD(capture,args);
	ENSURE_SINGLE_ARG(args,NSDictionary);
    
    [self rememberSelf];
	
	BOOL tryHarder = [TiUtils boolValue:[self valueForUndefinedKey:@"allowRotation"] def:NO];
    id acceptedFormats = [args valueForKey:@"acceptedFormats"];
    
	// [MOD-232] Allow caller to determine if they want to animate
	animate = [TiUtils boolValue:[args objectForKey:@"animate"] def:YES];
	
	if (controller!=nil)
	{
        NSMutableDictionary *event = [NSMutableDictionary dictionary];
        [event setObject:@"device busy" forKey:@"message"];
        [self fireEvent:@"error" withObject:event];
		return;
	}
	
    keepOpen = [TiUtils boolValue:@"keepOpen" properties:args def:NO];
    
    // allow an overlay view
    UIView *overlayView = nil;
    TiViewProxy *overlayProxy = [args objectForKey:@"overlay"];
    if (overlayProxy != nil)
    {
        ENSURE_TYPE(overlayProxy, TiViewProxy);
        overlayView = [overlayProxy view];
        
        //[overlayProxy layoutChildren:NO];
        [TiUtils setView:overlayView positionRect:[UIScreen mainScreen].bounds];
    }
    
	controller = [[ZXingWidgetController alloc] initWithDelegate:self
													  showCancel:[TiUtils boolValue:@"showCancel" properties:args def:YES]
                                                   showRectangle:[TiUtils boolValue:@"showRectangle" properties:args def:YES]
                                                        keepOpen:keepOpen
                                                  useFrontCamera:useFrontCamera
                                                        OneDMode:NO
                                                     withOverlay:overlayView];
    
    [controller setTorch:led];
	
	// Use our custom multi-format reader so that we get all of the formats and
	// we can control the 'TryHarder' flag for rotation support
	CustomMultiFormatReader* multiFormatReader = [[CustomMultiFormatReader alloc] init];
	[multiFormatReader setTryHarder:tryHarder];
    if (acceptedFormats != nil) {
        ENSURE_ARRAY(acceptedFormats);
        [multiFormatReader setAcceptedFormats:acceptedFormats];
    }
    
	NSString* displayedMessage = [TiUtils stringValue:[self valueForUndefinedKey:@"displayedMessage"]];
	if (displayedMessage != nil) {
	    controller.overlayView.displayedMessage = displayedMessage;
    }
	
	NSSet *readers = [[NSSet alloc] initWithObjects:
					  multiFormatReader,
					  nil];
	
	[multiFormatReader release];
	
	controller.readers = readers;
	[readers release];
    
	id sound = [args objectForKey:@"soundURL"];
	if (sound!=nil)
	{
		NSURL *soundURL = [TiUtils toURL:sound proxy:self];
		if (soundURL!=nil)
		{
			[controller setSoundToPlay:soundURL];
		}
	}
	
	[[TiApp app] showModalController:controller animated:YES];
}

-(void)cancel:(id)args
{
	ENSURE_UI_THREAD(cancel,args);
	
	if (controller!=nil)
	{
		[self performSelector:@selector(zxingControllerDidCancel:) withObject:nil];
	}
}

#pragma mark System Properties

MAKE_SYSTEM_PROP(UNKNOWN,0);
MAKE_SYSTEM_PROP(URL,1);
MAKE_SYSTEM_PROP(SMS,2);
MAKE_SYSTEM_PROP(TELEPHONE,3);
MAKE_SYSTEM_PROP(TEXT,4);
MAKE_SYSTEM_PROP(CALENDAR,5);
MAKE_SYSTEM_PROP(GEOLOCATION,6);
MAKE_SYSTEM_PROP(EMAIL,7);
MAKE_SYSTEM_PROP(CONTACT,8);
MAKE_SYSTEM_PROP(BOOKMARK,9);
MAKE_SYSTEM_PROP(WIFI,10);

MAKE_SYSTEM_PROP(FORMAT_NONE,zxing::BarcodeFormat_None);
MAKE_SYSTEM_PROP(FORMAT_QR_CODE,zxing::BarcodeFormat_QR_CODE);
MAKE_SYSTEM_PROP(FORMAT_DATA_MATRIX,zxing::BarcodeFormat_DATA_MATRIX);
MAKE_SYSTEM_PROP(FORMAT_UPC_E,zxing::BarcodeFormat_UPC_E);
MAKE_SYSTEM_PROP(FORMAT_UPC_A,zxing::BarcodeFormat_UPC_A);
MAKE_SYSTEM_PROP(FORMAT_EAN_8,zxing::BarcodeFormat_EAN_8);
MAKE_SYSTEM_PROP(FORMAT_EAN_13,zxing::BarcodeFormat_EAN_13);
MAKE_SYSTEM_PROP(FORMAT_CODE_128,zxing::BarcodeFormat_CODE_128);
MAKE_SYSTEM_PROP(FORMAT_CODE_39,zxing::BarcodeFormat_CODE_39);
MAKE_SYSTEM_PROP(FORMAT_ITF,zxing::BarcodeFormat_ITF);


#pragma mark Parsing Utility Methods

-(void)parseMeCard: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:7];
	NSArray *tokens = [payload componentsSeparatedByString:@";"];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	for (NSString *token in tokens)
	{
		NSRange range = [token rangeOfString:@":"];
		if (range.location==NSNotFound) continue;
		NSString *key = [token substringToIndex:range.location];
		if ([key isEqualToString:@""]) continue;
		NSString *value = [token substringFromIndex:range.location+1];
		if ([key isEqualToString:@"N"])
		{
			key = @"NAME";
		}
		value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
		[data setObject:value forKey:[key lowercaseString]];
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseWifi: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:5];
	NSArray *tokens = [payload componentsSeparatedByString:@";"];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	for (NSString *token in tokens)
	{
		NSRange range = [token rangeOfString:@":"];
		if (range.location==NSNotFound) continue;
		NSString *key = [token substringToIndex:range.location];
		if ([key isEqualToString:@""]) continue;
		NSString *value = [token substringFromIndex:range.location+1];
		value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
		[data setObject:value forKey:[key lowercaseString]];
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseBookmark: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:6];
	NSArray *tokens = [payload componentsSeparatedByString:@";"];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	for (NSString *token in tokens)
	{
		NSRange range = [token rangeOfString:@":"];
		if (range.location==NSNotFound) continue;
		NSString *key = [token substringToIndex:range.location];
		if ([key isEqualToString:@""]) continue;
		NSString *value = [token substringFromIndex:range.location+1];
		value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
		[data setObject:value forKey:[key lowercaseString]];
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseGeolocation: (NSMutableDictionary*)event withString:(NSString*)content
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

-(void)parseMailto: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:7];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:payload forKey:@"email"];
	[event setObject:data forKey:@"data"];
}

-(void)parseTel: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:4];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:payload forKey:@"phonenumber"];
	[event setObject:data forKey:@"data"];
}

-(void)parseSms: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:4];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	[data setObject:payload forKey:@"phonenumber"];
	[event setObject:data forKey:@"data"];
}

-(void)parseSmsTo: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:6];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	NSRange range = [payload rangeOfString:@":"];
	if (range.location==NSNotFound)
	{
		[data setObject:payload forKey:@"phonenumber"];
	}
	else
	{
		[data setObject:[payload substringToIndex:range.location] forKey:@"phonenumber"];
		[data setObject:[payload substringFromIndex:range.location+1] forKey:@"message"];
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseEmailto: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSString *payload = [content substringFromIndex:5];
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	NSArray *tokens = [payload componentsSeparatedByString:@":"];
	// format  SMTP:[email address]:[subject]:[message]
	try {
        if ([tokens count] >= 1)
            [data setObject:[tokens objectAtIndex:0] forKey:@"email"];
        if ([tokens count] >= 2)
            [data setObject:[tokens objectAtIndex:1] forKey:@"subject"];
        if ([tokens count] >= 3)
            [data setObject:[tokens objectAtIndex:2] forKey:@"message"];
	}
	catch (NSException *e) {
		NSLog(@"[WARN] Not all parameters available for parsing E-Mail");
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseVcard: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	for (NSString *token in [content componentsSeparatedByString:@"\n"])
	{
		if ([token hasPrefix:@"BEGIN:VCARD"]) continue;
		if ([token hasPrefix:@"END:VCARD"]) break;
		NSRange range = [token rangeOfString:@":"];
		if (range.location==NSNotFound) continue;
		NSString *key = [token substringToIndex:range.location];
		NSString *value = [token substringFromIndex:range.location+1];
		if ([key isEqualToString:@"N"])
		{
			key = @"NAME";
		}
		value = [value stringByReplacingOccurrencesOfString:@"\\:" withString:@":"];
		[data setObject:value forKey:[key lowercaseString]];
	}
	[event setObject:data forKey:@"data"];
}

-(void)parseVevent: (NSMutableDictionary*)event withString:(NSString*)content
{
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	for (NSString *token in [content componentsSeparatedByString:@"\n"])
	{
		if ([token hasPrefix:@"BEGIN:VEVENT"]) continue;
		if ([token hasPrefix:@"END:VEVENT"]) break;
		NSRange range = [token rangeOfString:@":"];
		if (range.location==NSNotFound) continue;
		NSString *key = [token substringToIndex:range.location];
		id value = [token substringFromIndex:range.location+1];
		if ([key isEqualToString:@"N"])
		{
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

#pragma mark Delegate Utility

- (void)parseSuccessResult:(NSString *)result
{
    NSLog(@"[DEBUG] Received barcode result = %@", result);
	
	NSMutableDictionary *event = [NSMutableDictionary dictionary];
	[event setObject:result forKey:@"result"];
	NSString *prefixCheck = [[result substringToIndex:MIN(20,[result length])] lowercaseString];
	if ([prefixCheck hasPrefix:@"http://"] || [prefixCheck hasPrefix:@"https://"])
	{
		[event setObject:[self URL] forKey:@"contentType"];
	}
	else if ([prefixCheck hasPrefix:@"sms:"])
	{
		[event setObject:[self SMS] forKey:@"contentType"];
		[self parseSms:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"smsto:"])
	{
		[event setObject:[self SMS] forKey:@"contentType"];
		[self parseSmsTo:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"tel:"])
	{
		[event setObject:[self TELEPHONE] forKey:@"contentType"];
		[self parseTel:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"begin:vevent"])
	{
		[event setObject:[self CALENDAR] forKey:@"contentType"];
		[self parseVevent:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"mecard:"])
	{
		[event setObject:[self CONTACT] forKey:@"contentType"];
		[self parseMeCard:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"begin:vcard"])
	{
		[event setObject:[self CONTACT] forKey:@"contentType"];
		[self parseVcard:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"mailto:"])
	{
		[event setObject:[self EMAIL] forKey:@"contentType"];
		[self parseMailto:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"smtp:"])
	{
		[event setObject:[self EMAIL] forKey:@"contentType"];
		[self parseEmailto:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"geo:"])
	{
		[event setObject:[self GEOLOCATION] forKey:@"contentType"];
		[self parseGeolocation:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"mebkm:"])
	{
		[event setObject:[self BOOKMARK] forKey:@"contentType"];
		[self parseBookmark:event withString:result];
	}
	else if ([prefixCheck hasPrefix:@"wifi:"])
	{
		[event setObject:[self WIFI] forKey:@"contentType"];
		[self parseWifi:event withString:result];
	}
	else
	{
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
    @catch (NSException * e) {
        [self fireEvent:@"error" withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[e reason], @"message", nil]];
    }
}

#pragma mark ZXing Delegate

- (void)zxingController:(ZXingWidgetController*)controller_ didScanResult:(NSString *)result
{
	[self handleSuccessResult:result];
    if (!keepOpen) {
        [self _cleanup];
    }
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller_
{
    [self fireEvent:@"cancel" withObject:[NSMutableDictionary dictionary]];
	[self _cleanup];
}

#pragma mark Decoder Delegate

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result
{
    [self handleSuccessResult:result.text];
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason
{
    [self fireEvent:@"error" withObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:reason, @"message", nil]];
}

@end
