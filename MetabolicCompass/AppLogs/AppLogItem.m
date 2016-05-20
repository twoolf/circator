//
//  AppLogItem.m
//  Rituals
//
//  Created by Vladimir on 2/29/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogItem.h"

NSString * const kAppLogNotShownTitleKey = @"title";
NSString * const kAppLogErrorKey = @"Error";

@interface AppLogItem()

@property(nonatomic, strong) NSDate * date;
@property(nonatomic, strong) NSDictionary * values;
@property(nonatomic, strong) NSError * error;

@end

@implementation AppLogItem
@dynamic title, itemName, eventType;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.date = [NSDate date];
    }
    return self;
}

+ (instancetype) newWithValues:(NSDictionary *)values{
    AppLogItem * item = [self new];
    item.values = values;
    return item;
}

+ (instancetype) newWithTitle:(NSString *)title error:(NSError *)error{
    if (error == nil){
        return  [self newWithValues:@{kAppLogNotShownTitleKey:title ?: @""}];
    }
    else{
        AppLogItem * item = [self new];
        item.values = @{kAppLogNotShownTitleKey:title ?: @"", kAppLogErrorKey:[error localizedDescription] ?: @""};
        return item;
    }
}

- (NSString *)itemName{
    return @"Log";
}


- (NSArray *)fields{
    if (self.error != nil){
        return @[kAppLogNotShownTitleKey, kAppLogErrorKey];
    }
    else{
        return @[kAppLogNotShownTitleKey];
    }
}

- (NSString *)title{
    return self.values[kAppLogNotShownTitleKey] ?: @"";
}

- (AppLogEventType) eventType{
    return (self.error) ? AppLogEventTypeError : AppLogEventTypeLog;
}

- (NSString *)description{
    NSMutableString * res = [NSMutableString new];
    NSString * format = @"dd.MM hh:mm:ss.SS";
    [res appendFormat:@"%@: %@\n", self.itemName, [[self dateFormatterWithFormat:format] stringFromDate:self.date]];
    for (NSString * fieldName in self.fields) {
        if (fieldName != kAppLogNotShownTitleKey){
            [res appendFormat:@"%@:\n",fieldName];
        }
        [res appendFormat:@"%@\n", self.values[fieldName]];
    }
    return [NSString stringWithString:res];
}

- (NSDateFormatter *)dateFormatterWithFormat:(NSString *)format{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:format];
    return formatter;
}

@end


@implementation AppLogInfoItem

- (AppLogEventType) eventType{
    return AppLogEventTypeInfo;
}

- (NSString *)itemName{
    return @"Info";
}

@end

@implementation AppLogMethodItem

+ (instancetype) newWithValues:(NSDictionary *)values{
    NSMutableDictionary * mDict = [NSMutableDictionary new];
    [mDict addEntriesFromDictionary:values];
    [mDict setValue:[[NSThread callStackSymbols] description] forKey:@"Callstack"];
    return [super newWithValues:[NSDictionary dictionaryWithDictionary:mDict]];
}



- (NSArray *)fields{
    if (self.error != nil){
        return @[kAppLogNotShownTitleKey, @"Callstack", kAppLogErrorKey];
    }
    else{
        return @[kAppLogNotShownTitleKey, @"Callstack"];
    }
    
}



@end



