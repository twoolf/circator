//
//  UIView+LayerProperties.h
//  Rituals
//
//  Created by Vladimir on 1/21/16.
//  Copyright © 2016 How Else. All rights reserved.
//

IB_DESIGNABLE

@import UIKit;

@interface UIView (LayerProperties)

@property (assign, nonatomic) IBInspectable CGFloat borderWidth;
@property (assign, nonatomic) IBInspectable UIColor *borderColor;

@property (assign, nonatomic) IBInspectable CGFloat cornerRadius;

//@property (assign, nonatomic) CGFloat borderWidth;
//@property (assign, nonatomic) UIColor *borderColor;
//
//@property (assign, nonatomic) CGFloat cornerRadius;

@end
