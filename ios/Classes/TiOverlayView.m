/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2018 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiOverlayView.h"

#define kTextMargin 10
CGFloat _kPadding = 10;

@implementation TiOverlayView

- (id)initWithFrame:(CGRect)frame
         showCancel:(BOOL)showCancel
      showRectangle:(BOOL)showRectangle
        withOverlay:(UIView *)overlay
{
  self = [super initWithFrame:frame];
  if (self) {
    _showRectangle = showRectangle;
    self.backgroundColor = [UIColor clearColor];
    if (showCancel) {
      _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
      [_cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
      [self addSubview:_cancelButton];
    }

    [self updateViewsWithFrame:frame];

    if (overlay != nil) {
      [self.layer addSublayer:overlay.layer];
    }
  }
  return self;
}

- (void)updateViewsWithFrame:(CGRect)newFrame
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

  if (_cancelButton) {
    CGSize theSize = CGSizeMake(100, 50);
    CGRect theRect = CGRectMake((self.frame.size.width - theSize.width) / 2, _cropRect.origin.y + _cropRect.size.height + 20, theSize.width, theSize.height);
    [_cancelButton setFrame:theRect];
  }
  [self setNeedsDisplay];
}

- (void)cancel:(id)sender
{
  if (self.delegate != nil) {
    [self.delegate cancelled];
  }
}

- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context
{
  if (_showRectangle) {
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
    CGContextStrokePath(context);
  }
}

- (void)drawRect:(CGRect)rect
{
  [super drawRect:rect];
  if (_displayMessage == nil) {
    self.displayMessage = @"Place the barcode inside the rectangle to scan it.";
  }
  CGContextRef c = UIGraphicsGetCurrentContext();

  if (_showRectangle) {
    CGFloat white[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
    CGContextSetStrokeColor(c, white);
    CGContextSetFillColor(c, white);
    [self drawRect:_cropRect inContext:c];
    CGContextSaveGState(c);
    UIFont *font = [UIFont systemFontOfSize:18];
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle alloc] init];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    CGSize constraint = CGSizeMake(rect.size.width - 2 * kTextMargin, _cropRect.origin.y);
    CGSize displaySize = [self.displayMessage boundingRectWithSize:constraint options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : font, NSParagraphStyleAttributeName : textStyle } context:nil].size;
    CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2, _cropRect.origin.y - displaySize.height, displaySize.width, displaySize.height);
    [self.displayMessage drawInRect:displayRect
                     withAttributes:@{ NSFontAttributeName : font,
                       NSParagraphStyleAttributeName : textStyle,
                       NSForegroundColorAttributeName : UIColor.whiteColor }];
    CGContextRestoreGState(c);
  }
}

@end
