//
//  NetworkRequestResult.h
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLogItem.h"

@interface NetworkRequestResult : NSObject

@property(nonatomic, strong) NSURLRequest * request;
@property(nonatomic, strong) NSURLResponse * response;
@property(nonatomic, strong) id responseObject;
@property(nonatomic, strong) NSError * error;
@property(nonatomic, strong) NSDate * date;
@property(nonatomic, readonly) NSString * requestBodyText;
@property(nonatomic, readonly) NSHTTPURLResponse * httpResponse;

@end

@interface AppLogNetworkRequestItem : AppLogItem

+ (instancetype) newWithRequestResult:(NetworkRequestResult *)requestResult;

@end