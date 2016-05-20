//
//  NetworkRequestResult.m
//  Rituals
//
//  Created by Vladimir on 3/1/16.
//  Copyright © 2016 How Else. All rights reserved.
//

#import "AppLogNetworkRequestItem.h"

static NSString * const kAppLogNetworkKeyRequestInfo = @"Request";
static NSString * const kAppLogNetworkKeyError = @"Error";
static NSString * const kAppLogNetworkKeyStatusCode = @"Status code";
static NSString * const kAppLogNetworkKeyHeaders = @"Request headers";
static NSString * const kAppLogNetworkKeyResponseObject = @"Response object";
static NSString * const kAppLogNetworkKeyRequestBody = @"Request body";

@implementation NetworkRequestResult

- (NSString *) requestBodyText{
    NSString * str = [[NSString alloc] initWithData:self.request.HTTPBody encoding:NSUTF8StringEncoding];
    return str;
}

- (NSString *)description{
    NSString * urlString = self.request.URL.absoluteString;
    NSString * errorString = (self.error) ? [NSString stringWithFormat:@"Error:%@", self.error.localizedDescription] : @"";
    return [NSString stringWithFormat:@"URL:%@\nBody:%@\nResponse:%@\n%@", urlString, self.requestBodyText, [self.responseObject description], errorString];
}

- (NSHTTPURLResponse *) httpResponse{
    return (NSHTTPURLResponse *) self.response;
}

@end


@interface AppLogNetworkRequestItem()

@property(nonatomic, strong) NetworkRequestResult * requestResult;

@end

@implementation AppLogNetworkRequestItem

+ (instancetype) newWithRequestResult:(NetworkRequestResult *)requestResult{
    NSMutableDictionary * mDict = [NSMutableDictionary new];
    if (requestResult.error != nil){
        mDict[kAppLogNetworkKeyError] = requestResult.error.localizedDescription;
    }
    mDict[kAppLogNetworkKeyRequestInfo] = [NSString stringWithFormat:@"%@ %@", requestResult.request.HTTPMethod, requestResult.request.URL.absoluteString ?: @"?"];
    mDict[kAppLogNetworkKeyStatusCode] = [NSString stringWithFormat:@"%@", @(requestResult.httpResponse.statusCode)];
    mDict[kAppLogNetworkKeyHeaders] = [[requestResult.request allHTTPHeaderFields] description] ?: @"";
    mDict[kAppLogNetworkKeyResponseObject] = [requestResult.responseObject description] ?: @"";
    mDict[kAppLogNetworkKeyRequestBody] = requestResult.requestBodyText ?: @"";

    AppLogNetworkRequestItem * item = [super newWithValues:[NSDictionary dictionaryWithDictionary:mDict]];
    item.requestResult = requestResult;
    return item;
}

- (AppLogEventType) eventType{
    if (self.requestResult.error != nil){
        return AppLogEventTypeError;
    }
    else{
        return AppLogEventTypeOK;
    }
}

- (NSString *)title{
    return self.values[kAppLogNetworkKeyRequestInfo] ?: @"";
}

- (NSString *)itemName{
    return @"Request";
}

- (NSArray *)fields{
    return @[kAppLogNetworkKeyRequestInfo, kAppLogNetworkKeyRequestBody, kAppLogNetworkKeyHeaders, kAppLogNetworkKeyStatusCode, kAppLogNetworkKeyResponseObject, kAppLogNetworkKeyError];
}

@end
