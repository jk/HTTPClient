//
//  HCHistoryManager.m
//  HTTPClient
//
//  Created by Todd Ditchendorf on 2/15/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "HCHistoryManager.h"
#import "HCAppDelegate.h"

static const NSInteger kHCHistoryListCount = 25;

static HCHistoryManager *instance = nil;

@implementation HCHistoryManager

+ (HCHistoryManager *)instance {
    @synchronized(self) {
        if (instance == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return instance;
}


+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (instance == nil) {
            instance = [super allocWithZone:zone];
            return instance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}


- (void)dealloc {
	[super dealloc];
}


- (id)retain {
    return self;
}


- (NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}


- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}


- (NSInteger)count {
	return [[listController arrangedObjects] count];
}


- (NSString *)objectAtIndex:(NSInteger)i {
	return [[listController arrangedObjects] objectAtIndex:i];
}


- (void)add:(NSString *)URLString {
	if (!URLString.length) return;

	NSInteger i = [[listController arrangedObjects] indexOfObject:URLString];
	
	// if URLString is not already present, and the list is already at the limit count, remove first item
	if (NSNotFound == i && [self count] >= kHCHistoryListCount) {
		i = 0;
	}

	if (NSNotFound != i) {
		[listController removeObjectAtArrangedObjectIndex:i];
	}
	
	[listController addObject:URLString];
}


#pragma mark -
#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
	return [self count];
}


- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
	[item setTitle:[self objectAtIndex:index]];

	// nil-target the action so it will be sent to the frontmost HCWindowController
	[item setTarget:nil];
	[item setAction:@selector(historyMenuItemAction:)];
	[item setState:NSOffState];
	
	return YES;
}

@end
