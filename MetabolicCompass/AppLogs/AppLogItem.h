//
//  AppLogItem.h
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const kAppLogNotShownTitleKey;
extern NSString * const kAppLogErrorKey;

typedef NS_ENUM(NSUInteger, AppLogEventType){
    AppLogEventTypeLog = 0,
    AppLogEventTypeInfo,
    AppLogEventTypeOK,
    AppLogEventTypeWarning,
    AppLogEventTypeError
};


@interface AppLogItem : NSObject

@property(nonatomic, readonly) NSArray * fields;
@property(nonatomic, readonly) NSDate * date;
@property(nonatomic, readonly) NSString * title;
@property(nonatomic, readonly) NSString * itemName;
@property(nonatomic, readonly) AppLogEventType eventType;
@property(nonatomic, readonly) NSDictionary * values;

+ (instancetype) newWithValues:(NSDictionary *)values;
+ (instancetype) newWithTitle:(NSString *)title error:(NSError *)error;

@end

@interface AppLogInfoItem : AppLogItem
@end

@interface AppLogMethodItem : AppLogItem
@end

