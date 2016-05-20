//
//  AppLogManager.m
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogManager.h"
#import "AppLogItem.h"
#import "AppLogUrlProtocol.h"
#import "AppLogViewController.h"

NSString * const ncAppLogItemsChanged = @"ncAppLogItemsChanged";

//void addAppError(NSString *format, ... ){
//    va_list args;
//    va_start(args, format);
//    NSString * str = [[NSString alloc] initWithFormat:format arguments:args];
//    [[HCDataManager sharedInstance] addAppEventWithType:AppLogEventTypeError text:str];
//    va_end(args);
//}
//

void addAppInfo(NSString *format, ... ){
    va_list args;
    va_start(args, format);
    NSString * str = [[NSString alloc] initWithFormat:format arguments:args];
    [[AppLogManager sharedInstance] addAppLogItem:[AppLogInfoItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    va_end(args);
}

void addAppLog(NSString *format, ... ){
    va_list args;
    va_start(args, format);
    NSString * str = [[NSString alloc] initWithFormat:format arguments:args];
    [[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    va_end(args);
}

void addAppErrorLog(NSString * title, NSError * error){
    [[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithTitle:title error:error]];
}


@interface AppLogManager(){

}

@property(nonatomic, strong) NSMutableArray * mAppLogItems;

@end


@implementation AppLogManager
@dynamic appLogItems;

#pragma mark - Shared access & init

+ (instancetype)sharedInstance
{
    static dispatch_once_t predicate;
    static id sharedInstance = nil;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [AppLogManager new];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mAppLogItems = [NSMutableArray new];
    }
    return self;
}

#pragma mark LOG SINGLE ITEM

//Use these methods to manually log single items

- (void) addAppLogItem:(AppLogItem *)appLogItem{
    [self.mAppLogItems addObject:appLogItem];
    [[NSNotificationCenter defaultCenter] postNotificationName:ncAppLogItemsChanged object:nil];
}

- (NSArray *)appLogItems{
    return [NSArray arrayWithArray:self.mAppLogItems];
}

#pragma mark UI SETUP

//This method adds gesture recognizers to given window
- (void) addAppLogRecognizersToView: (UIView *)view{
    [AppLogViewController addAppLogRecognizersToView:view];
}

//This method adds gesture recognizers to current window
- (void) addAppLogRecognizersToGlobalWindow{
    [AppLogViewController addAppLogRecognizersToGlobalWindow];
}

#pragma mark URL Proxy setup

- (void) startGlobalLogger{
    [NSURLProtocol registerClass:[AppLogUrlProtocol class]];
}

- (void) stopGlobalLogger{
    [NSURLProtocol unregisterClass:[AppLogUrlProtocol class]];
}

@end
