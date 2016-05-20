//
//  AppLogFieldView.h
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppLogFieldView : UIView
@property (readonly, nonatomic) UILabel *titleLabel;
@property (readonly, nonatomic) UILabel *textLabel;
@property(nonatomic, strong) UIColor * backViewColor;

@end
