//
//  HTTPServiceCFNetworkImpl.h
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPService.h"
#import "HCAppDelegate.h"

@interface HTTPServiceCFNetworkImpl : NSObject <HTTPService> {
    id delegate;
    NSMutableDictionary *command;
    NSString *authUsername;
    NSString *authPassword;
}
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) id command;
@property (nonatomic, copy) NSString *authUsername;
@property (nonatomic, copy) NSString *authPassword;
@end
