//
//  AppLogUrlProtocol.m
//  Pods
//
//  Created by Srost 3/22/16.
//
//

#import "AppLogUrlProtocol.h"
#import "AppLogManager.h"
#import "AppLogNetworkRequestItem.h"

static NSString * const MyURLProtocolHandledKey = @"MyURLProtocolHandledKey";

@interface AppLogUrlProtocol ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation AppLogUrlProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if ([NSURLProtocol propertyForKey:MyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {

    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:MyURLProtocolHandledKey inRequest:newRequest];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];

}

- (void) stopLoading {
    
    [self.connection cancel];
    self.mutableData = nil;
    
}

#pragma mark - NSURLConnectionDelegate

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    
    [self.mutableData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    NetworkRequestResult * requestResult = [NetworkRequestResult new];
    requestResult.request = self.request;
    requestResult.response = self.response;
    requestResult.responseObject = self.response;
    AppLogNetworkRequestItem * logItem = [AppLogNetworkRequestItem newWithRequestResult:requestResult];
    [[AppLogManager sharedInstance] addAppLogItem:logItem];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
    NetworkRequestResult * requestResult = [NetworkRequestResult new];
    requestResult.request = self.request;
    requestResult.response = self.response;
    requestResult.responseObject = self.response;
    requestResult.error = error;
    AppLogNetworkRequestItem * logItem = [AppLogNetworkRequestItem newWithRequestResult:requestResult];
    [[AppLogManager sharedInstance] addAppLogItem:logItem];
}


@end
