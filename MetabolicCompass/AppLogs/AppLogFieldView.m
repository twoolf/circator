//
//  AppLogFieldView.m
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogFieldView.h"
#import "Masonry.h"

@interface AppLogFieldView()
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *textLabel;
@property(nonatomic, strong) UIView * backView;

@end

@implementation AppLogFieldView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView * backView = [UIView new];
        backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backView.layer.borderColor = [UIColor blackColor].CGColor;
        backView.layer.borderWidth = 1.0;
        backView.layer.cornerRadius = 5.0;
        
        [self addSubview:backView];
        self.backView = backView;
        
        UILabel * titleLabel = [UILabel new];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        UILabel * textLabel = [UILabel new];
        textLabel.textColor = [UIColor blackColor];
        textLabel.font = [UIFont systemFontOfSize:13.0];
        textLabel.textAlignment = NSTextAlignmentLeft;
        textLabel.numberOfLines = 0;
        [self addSubview:textLabel];
        self.textLabel = textLabel;
        

        [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsZero);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).with.offset(8.0);
            make.right.equalTo(self.mas_right).with.offset(-8.0);
            make.top.equalTo(self.mas_top).with.offset(8.0);
            //make.bottom.equalTo(self.mas_bottom).with.offset(-8.0);
        }];
        
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left).with.offset(8.0);
            make.right.equalTo(self.mas_right).with.offset(-8.0);
            make.top.equalTo(self.titleLabel.mas_bottom).with.offset(8.0);
            make.bottom.equalTo(self.mas_bottom).with.offset(-8.0);
        }];
        
        

    }
    return self;
}

- (UIColor *) backViewColor{
    return self.backView.backgroundColor;
}

- (void) setBackViewColor:(UIColor *)backViewColor{
    self.backView.backgroundColor = backViewColor;
}

@end
