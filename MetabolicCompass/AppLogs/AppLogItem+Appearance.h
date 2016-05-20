//
//  AppLogAppearance.h
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLogItem.h"

@interface AppLogItem(Appearance)

- (UIColor *) backgroundColor;

- (UIColor *) colorWithHexValue:(NSUInteger)aHexValue alpha:(float)anAlpha;

@end
