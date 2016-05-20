//
//  AppLogAppearance.m
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogItem+Appearance.h"

@implementation AppLogItem(Appearance)

- (UIColor *) backgroundColor{
    NSInteger  hColor;
    switch (self.eventType) {
        case AppLogEventTypeInfo:
            hColor = 0xDDDDFF;
            break;
        case AppLogEventTypeOK:
            hColor = 0xCCFFCC;
            break;
        case AppLogEventTypeWarning:
            hColor = 0xDDDDCC;
            break;
        case AppLogEventTypeError:
            hColor = 0xFFCCCC;
            break;
        case AppLogEventTypeLog:
        default:
            hColor = 0xDDEEDD;

    }
    return [self colorWithHexValue:hColor];
}

- (UIColor *) colorWithHexValue:(NSUInteger)aHexValue{
    NSUInteger b = aHexValue % 0x100;
    NSUInteger g = (aHexValue / 0x100) % 0x100;
    NSUInteger r = (aHexValue / 0x10000);
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

@end
