//
//  UIView+LayerProperties.m
//  Rituals
//
//  Created by Vladimir on 1/21/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "UIView+LayerProperties.h"

@implementation UIView (LayerProperties)

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = [borderColor CGColor];
}

- (UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}

@end
