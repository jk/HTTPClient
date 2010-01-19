//
//  HCPreferencesWindowController.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCPreferencesWindowController.h"
#import "HCAppDelegate.h"

@implementation HCPreferencesWindowController

+ (id)instance {
    static id instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[HCPreferencesWindowController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    self = [super initWithWindowNibName:@"HCPreferencesWindow"];
    if (self) {
        
    }
    return self;
}


- (void)dealloc {
    [super dealloc];
}


- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [[self window] center];
}


- (void)wrapTextChanged:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:HCWrapRequestResponseTextChangedNotification object:nil];
}


- (void)syntaxHightlightTextChanged:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:HCSyntaxHighlightRequestResponseTextChangedNotification object:nil];
}

@end
