/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiModule.h"
#import "ZXingWidgetController.h"
#import "DecoderDelegate.h"
#import "TwoDDecoderResult.h"

@interface TiBarcodeModule : TiModule<ZXingDelegate, DecoderDelegate> 
{
	ZXingWidgetController *controller;
	BOOL animate;
    BOOL keepOpen;
    BOOL useFrontCamera;
    BOOL led;
}

@property(nonatomic,readonly) NSNumber *UNKNOWN;
@property(nonatomic,readonly) NSNumber *URL;
@property(nonatomic,readonly) NSNumber *SMS;
@property(nonatomic,readonly) NSNumber *TELEPHONE;
@property(nonatomic,readonly) NSNumber *TEXT;
@property(nonatomic,readonly) NSNumber *CALENDAR;
@property(nonatomic,readonly) NSNumber *GEOLOCATION;
@property(nonatomic,readonly) NSNumber *EMAIL;
@property(nonatomic,readonly) NSNumber *CONTACT;
@property(nonatomic,readonly) NSNumber *BOOKMARK;
@property(nonatomic,readonly) NSNumber *WIFI;

@property(nonatomic,readonly) NSNumber *FORMAT_NONE;
@property(nonatomic,readonly) NSNumber *FORMAT_QR_CODE;
@property(nonatomic,readonly) NSNumber *FORMAT_DATA_MATRIX;
@property(nonatomic,readonly) NSNumber *FORMAT_UPC_E;
@property(nonatomic,readonly) NSNumber *FORMAT_UPC_A;
@property(nonatomic,readonly) NSNumber *FORMAT_EAN_8;
@property(nonatomic,readonly) NSNumber *FORMAT_EAN_13;
@property(nonatomic,readonly) NSNumber *FORMAT_CODE_128;
@property(nonatomic,readonly) NSNumber *FORMAT_CODE_39;
@property(nonatomic,readonly) NSNumber *FORMAT_ITF;

@end
