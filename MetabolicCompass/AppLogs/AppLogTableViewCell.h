//
//  AppLogTableViewCell.h
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppLogTableViewCell : UITableViewCell

@property(nonatomic, readonly) UILabel * infoLabel;
@property(nonatomic, readonly) UILabel * titleLabel;
@property(nonatomic, strong) UIColor * backViewColor;

@end
