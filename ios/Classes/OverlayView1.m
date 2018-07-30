/**
 * Copyright 2009 Jeff Verkoeyen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OverlayView1.h"

CGFloat _kPadding = 10;

@interface OverlayView1()
@end


@implementation OverlayView1

- (id) initWithFrame:(CGRect)theFrame
       cancelEnabled:(BOOL)isCancelEnabled
    rectangleEnabled:(BOOL)isRectangleEnabled
         withOverlay:(UIView*)overlay {
    self = [super initWithFrame:theFrame];
    if( self ) {
        rectangleEnabled = isRectangleEnabled;
        self.backgroundColor = [UIColor clearColor];        
        if (isCancelEnabled)
        {
            cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
            [cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:cancelButton];
        }
        
        [self updateViewsWithFrame:theFrame];
        
        if (overlay != nil)
        {
            [self addSubview:overlay];
        }
    }
    return self;
}

-(void)updateViewsWithFrame:(CGRect)newFrame
{
    self.frame = newFrame;
    if (self.frame.size.width > self.frame.size.height) {
        _kPadding = 70;
    } else {
        _kPadding = 10;
    }
    CGFloat rectSize = self.frame.size.width - _kPadding * 2;
    CGFloat rectSize2 = rectSize;
    if (self.frame.size.width > self.frame.size.height) {
      rectSize2 = self.frame.size.height - _kPadding * 2;
    }
  _cropRect = CGRectMake(_kPadding, (self.frame.size.height - rectSize2) / 2, rectSize, rectSize2);
  
  if (cancelButton)
  {
    CGSize theSize = CGSizeMake(100, 50);
    CGRect theRect = CGRectMake((self.frame.size.width - theSize.width) / 2, _cropRect.origin.y + _cropRect.size.height + 20, theSize.width, theSize.height);
    [cancelButton setFrame:theRect];
  }
}

- (void)cancel:(id)sender {
	if (self.delegate != nil) {
		[self.delegate cancelled];
	}
}

- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
    if (rectangleEnabled) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
        CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
        CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
        CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
        CGContextStrokePath(context);
    }
}

- (CGPoint)map:(CGPoint)point {
    CGPoint center;
    center.x = _cropRect.size.width/2;
    center.y = _cropRect.size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
        case 0:
            point.x = x;
            point.y = y;
            break;
        case 90:
            point.x = -y;
            point.y = x;
            break;
        case 180:
            point.x = -x;
            point.y = -y;
            break;
        case 270:
            point.x = y;
            point.y = -x;
            break;
    }
    point.x = point.x + center.x;
    point.y = point.y + center.y;
    return point;
}

#define kTextMargin 10

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
    if (_displayedMessage == nil) {
        self.displayedMessage = @"Place a barcode inside the viewfinder rectangle to scan it.";
    }
	CGContextRef c = UIGraphicsGetCurrentContext();
	
    int offset = rect.size.width / 2;
    if (rectangleEnabled) {
        CGFloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
        CGContextSetStrokeColor(c, white);
        CGContextSetFillColor(c, white);
        [self drawRect:_cropRect inContext:c];
        CGContextSaveGState(c);
        UIFont *font = [UIFont systemFontOfSize:18];
        CGSize constraint = CGSizeMake(rect.size.width  - 2 * kTextMargin, _cropRect.origin.y);
        CGSize displaySize = [self.displayedMessage sizeWithFont:font constrainedToSize:constraint];
        CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2 , _cropRect.origin.y - displaySize.height, displaySize.width, displaySize.height);
        [self.displayedMessage drawInRect:displayRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
        CGContextRestoreGState(c);
    }
}

@end
