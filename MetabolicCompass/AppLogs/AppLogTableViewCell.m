//
//  AppLogTableViewCell.m
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogTableViewCell.h"
#import "UIView+LayerProperties.h"

static CGSize const kPaddingSize = {5.0, 2.0};
static UIEdgeInsets const kInsets = {2.0, 2.0, 2.0, 2.0};

@interface AppLogTableViewCell()

@property(nonatomic, strong) UILabel * infoLabel;
@property(nonatomic, strong) UILabel * titleLabel;
@property(nonatomic, strong) UIView * backView;

@end


@implementation AppLogTableViewCell
@dynamic backViewColor;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView * backView = [UIView new];
        backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backView.borderColor = [UIColor blackColor];
        backView.borderWidth = 1.0;
        backView.cornerRadius = 5.0;
        
        [self.contentView addSubview:backView];
        self.backView = backView;
    
        UILabel * infoLabel = [UILabel new];
        infoLabel.textColor = [UIColor darkGrayColor];
        infoLabel.font = [UIFont systemFontOfSize:12.0];
        infoLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:infoLabel];
        self.infoLabel = infoLabel;
        
        UILabel * titleLabel = [UILabel new];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.font = [UIFont systemFontOfSize:13.0];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.numberOfLines = 0;
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGRect backRect = UIEdgeInsetsInsetRect(self.bounds, kInsets);
    CGSize backSize = backRect.size;
    
    self.backView.frame = backRect;
    
    CGRect infoRect = CGRectMake(kPaddingSize.width, kPaddingSize.height, backSize.width - kPaddingSize.width * 2,  15.0); //
    self.infoLabel.frame = infoRect;
    //NSLog(@"-.infoLabel:%@", self.infoLabel);
    CGFloat infoBottom = CGRectGetMaxY(infoRect);
    self.titleLabel.frame = CGRectMake(kPaddingSize.width, infoBottom + kPaddingSize.height, backSize.width - kPaddingSize.width * 2, backSize.height - infoBottom - kPaddingSize.height * 2);
     //NSLog(@"-titleLabel:%@", self.titleLabel);
}

- (UIColor *) backViewColor{
    return self.backView.backgroundColor;
}

- (void) setBackViewColor:(UIColor *)backViewColor{
    self.backView.backgroundColor = backViewColor;
}

@end
