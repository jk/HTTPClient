//
//  HTTPService.h
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTTPService <NSObject>
- (id)initWithDelegate:(id)d;
- (void)sendHTTPRequest:(id)cmd;
@end

@interface NSObject (HTTPServiceDelegate)
- (void)HTTPService:(id <HTTPService>)service didRecieveResponse:(NSString *)rawResponse forRequest:(id)cmd;
- (void)HTTPService:(id <HTTPService>)service request:(id)cmd didFail:(NSString *)msg;
- (void)HTTPServiceCanceled:(id <HTTPService>)service;
- (BOOL)getUsername:(NSString **)uname password:(NSString **)passwd forAuthScheme:(NSString *)scheme URL:(NSURL *)URL realm:(NSString *)realm domain:(NSURL *)domain forProxy:(BOOL)forProxy isRetry:(BOOL)isRetry;
@end