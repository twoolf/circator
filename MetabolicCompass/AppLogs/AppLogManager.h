//
//  AppLogManager.h
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLogItem.h"

extern NSString * const ncAppLogItemsChanged;

void addAppInfo(NSString *format, ... );
void addAppLog(NSString *format, ... );
void addAppErrorLog(NSString * title, NSError * error);

@interface AppLogManager : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic, strong) NSArray * appLogItems;

//Use these methods to manually log single items

- (void) addAppLogItem:(AppLogItem *)appLogItem;

//This method adds gesture recognizers to given window
- (void) addAppLogRecognizersToView: (UIView *)view;

//This method adds gesture recognizers to current app window
- (void) addAppLogRecognizersToGlobalWindow;

//global logger which can be added wherever you want
- (void) startGlobalLogger;

- (void) stopGlobalLogger;

@end
