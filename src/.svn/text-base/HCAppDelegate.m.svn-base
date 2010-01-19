//
//  HCAppDelegate.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCAppDelegate.h"
#import "HCDocument.h"
#import "HCWindowController.h"
#import "HCPreferencesWindowController.h"

NSString *HCHistoryListKey = @"HCHistoryList";
NSString *HCPlaySuccessFailureSoundsKey = @"HCPlaySuccessFailureSounds";
NSString *HCWrapRequestResponseTextKey = @"HCWrapRequestResponseText";
NSString *HCSyntaxHighlightRequestResponseTextKey = @"HCSyntaxHighlightRequestResponseText";
NSString *HCAcceptUnverifiableSSLTextKey = @"HCAcceptUnverifiableSSL";

NSString *HCWrapRequestResponseTextChangedNotification = @"HCWrapRequestResponseTextChangedNotification";
NSString *HCSyntaxHighlightRequestResponseTextChangedNotification = @"HCSyntaxHighlightRequestResponseTextChangedNotification";


@implementation HCAppDelegate

+ (void)initialize {
    if ([HCAppDelegate class] == self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultValues" ofType:@"plist"];
        id defaultValues = [NSDictionary dictionaryWithContentsOfFile:path];
        
        [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    }
}


- (id)init {
    self = [super init];
    if (self) {
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                           andSelector:@selector(getURLEvent:withReplyEvent:) 
                                                         forEventClass:kInternetEventClass 
                                                            andEventID:kAEGetURL];        
    }
    return self;
}


- (void)dealloc {
    [[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
    [super dealloc];
}


#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)n {
}


#pragma mark -
#pragma mark Actions

- (IBAction)showPreferences:(id)sender {
    [[HCPreferencesWindowController instance] showWindow:self];
}


#pragma mark -
#pragma mark Apple Events

- (void)getURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    NSError *err = nil;
    HCDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&err];
    if (err) {
        NSString *title = NSLocalizedString(@"Can't open URL sent from other application.", @"");
        NSString *msgFormat = NSLocalizedString(@"URL: %@\nError:%@", @"");
        NSString *defaultButton = NSLocalizedString(@"OK", @"");
        NSRunAlertPanel(title, msgFormat, defaultButton, nil, nil, URLString, err);
        return;
    }
    
    HCWindowController *winController = doc.windowController;

    id cmd = [NSMutableDictionary dictionaryWithObjectsAndKeys:
              URLString, @"URLString",
              @"GET", @"method",
              nil];
    winController.command = cmd;

    [winController execute:self];
}

@end
