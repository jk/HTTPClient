//
//  HCHistoryManager.h
//  HTTPClient
//
//  Created by Todd Ditchendorf on 2/15/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HCHistoryManager : NSObject {
	IBOutlet NSArrayController *listController;
}
+ (HCHistoryManager *)instance;

- (NSInteger)count;
- (NSString *)objectAtIndex:(NSInteger)i;
- (void)add:(NSString *)URLString;
@end
