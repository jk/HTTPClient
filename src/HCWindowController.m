//
//  HCWindowController.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCWindowController.h"
#import "HCWindowController+HTTPAuth.h"
#import "HCAppDelegate.h"
#import "HCPreferencesWindowController.h"
#import "HTTPService.h"
#import "TDSourceCodeTextView.h"
#import "TDHtmlSyntaxHighlighter.h"
#import "HCHistoryManager.h"

@interface HCWindowController ()
- (BOOL)shouldPlaySounds;
- (void)playSuccessSound;
- (void)playErrorSound;
- (void)wrapTextChanged:(NSNotification *)n;
- (void)syntaxHighlightTextChanged:(NSNotification *)n;
- (void)setupFonts;
- (void)setupHeadersTable;
- (void)setupBodyTextView;
- (NSFont *)miniSystemFont;
- (NSComboBoxCell *)comboBoxCellWithTag:(int)tag;
- (NSArray *)methodsWithPrefixInFieldEditor:(NSText *)text;
- (NSArray *)headerNamesWithPrefixInFieldEditor:(NSText *)text;
- (NSArray *)headerNamesWithPrefix:(NSString *)s;
- (BOOL)isNameRequiringTodaysDateString:(NSString *)name;
- (NSString *)todaysDateString;
- (void)changeSizeForBody;
- (void)renderGutters;
- (void)updateTextWrapInTextView:(NSTextView *)textView withinScrollView:(NSScrollView *)scrollView;
- (NSAttributedString *)attributedStringForString:(NSString *)s;
- (void)updateSoureCodeViews;
- (void)cleanUserAgentStringsInHeaders:(NSArray *)headers;
- (void)requestCompleted:(id)cmd;
@end

@implementation HCWindowController

- (id)init {
    self = [super initWithWindowNibName:@"HCDocumentWindow"];
    if (self) {
        self.service = [[[NSClassFromString(@"HTTPServiceCFNetworkImpl") alloc] initWithDelegate:self] autorelease];

        self.command = [NSMutableDictionary dictionary];
        [command setObject:@"GET" forKey:@"method"];
        
        self.methods = [NSArray arrayWithObjects:@"GET", @"POST", @"PUT", @"DELETE", @"HEAD", @"OPTIONS", @"TRACE", @"CONNECT", nil];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"HeaderNames" ofType:@"plist"];
        self.headerNames = [NSArray arrayWithContentsOfFile:path];
        
        path = [[NSBundle mainBundle] pathForResource:@"HeaderValues" ofType:@"plist"];
        self.headerValues = [NSDictionary dictionaryWithContentsOfFile:path];
        
        self.syntaxHighlighter = [[[TDHtmlSyntaxHighlighter alloc] initWithAttributesForDarkBackground:YES] autorelease]; // TODO. remove
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wrapTextChanged:)
                                                     name:HCWrapRequestResponseTextChangedNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(syntaxHighlightTextChanged:)
                                                     name:HCSyntaxHighlightRequestResponseTextChangedNotification 
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.service = nil;
    self.headersController = nil;
    self.command = nil;
    self.highlightedRawRequest = nil;
    self.highlightedRawResponse = nil;
    self.methods = nil;
    self.headerNames = nil;
    self.headerValues = nil;
    self.attachedFilePath = nil;
    self.attachedFilename = nil;
    self.syntaxHighlighter = nil;
    self.authUsername = nil;
    self.authPassword = nil;
    self.authMessage = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self setupFonts];
    [self setupHeadersTable];
    [self setupBodyTextView];
    [self updateSoureCodeViews];
    
    [headersController addObserver:self
                        forKeyPath:@"arrangedObjects"
                           options:NSKeyValueObservingOptionOld
                           context:NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [[self document] updateChangeCount:NSChangeDone];
}


#pragma mark -
#pragma mark Actions

- (IBAction)openLocation:(id)sender {
    [[self window] makeFirstResponder:URLComboBox];
}


- (IBAction)historyMenuItemAction:(id)sender {
	NSString *URLString = [sender title];
	
	//[URLComboBox setStringValue:URLString];
	[command setObject:URLString forKey:@"URLString"];
	[self execute:self];
}


- (IBAction)execute:(id)sender {
    [self clear:self];
    
    NSString *URLString = [command objectForKey:@"URLString"];
    if (![URLString length]) {
        NSBeep();
        return;
    }
    
    self.busy = YES;
    
    if (![URLString hasPrefix:@"http://"] && ![URLString hasPrefix:@"https://"]) {
        URLString = [NSString stringWithFormat:@"http://%@", URLString];
        [command setObject:URLString forKey:@"URLString"];
    }
        
    NSArray *headers = [headersController arrangedObjects];
    
    // trim out the user-friendly UA names in any user-agent string header values
    [self cleanUserAgentStringsInHeaders:headers];
    
    [command setObject:headers forKey:@"headers"];
    [service sendHTTPRequest:command];
}


- (IBAction)clear:(id)sender {
    [command setObject:@"" forKey:@"rawRequest"];
    [command setObject:@"" forKey:@"rawResponse"];
    [self renderGutters];
}


- (IBAction)showRequest:(id)sender {
    [tabView selectTabViewItemAtIndex:0];
}


- (IBAction)showResponse:(id)sender {
    [tabView selectTabViewItemAtIndex:1];
}


- (IBAction)showMultipartBodyView:(id)sender {
    self.bodyShown = YES;
    self.multipartBodyShown = YES;
}


- (IBAction)showNormalBodyView:(id)sender {
    self.bodyShown = YES;
    if (!self.isMultipartBodyShown) return;
    
    self.multipartBodyShown = NO;
    
    
}


- (IBAction)runAttachFileSheet:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    
    [panel beginSheetForDirectory:nil 
                             file:nil 
                            types:nil 
                   modalForWindow:[self window] 
                    modalDelegate:self 
                   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                      contextInfo:NULL];
}


- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)code contextInfo:(void *)ctx {
    if (NSOKButton == code) {
        self.attachedFilePath = [panel filename];
    }
}


#pragma mark -
#pragma mark Private

- (BOOL)shouldPlaySounds {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:HCPlaySuccessFailureSoundsKey] boolValue];
}


- (void)playSuccessSound {
    if ([self shouldPlaySounds]) {
        [[NSSound soundNamed:@"Hero"] play];
    }
}


- (void)playErrorSound {
    if ([self shouldPlaySounds]) {
        [[NSSound soundNamed:@"Basso"] play];
    }
}


- (void)wrapTextChanged:(NSNotification *)n {
    [self updateTextWrapInTextView:requestTextView withinScrollView:requestScrollView];
    [self updateTextWrapInTextView:responseTextView withinScrollView:responseScrollView];
    [self renderGutters];
}


- (void)syntaxHighlightTextChanged:(NSNotification *)n {
    [self updateSoureCodeViews];
}


- (void)setupFonts {
    NSFont *monaco = [NSFont fontWithName:@"Monaco" size:10.];
//    [bodyTextView setFont:monaco];
    [requestTextView setFont:monaco];
    [responseTextView setFont:monaco];
}


- (void)setupHeadersTable {
    [[headersTable tableColumnWithIdentifier:@"headerName"] setDataCell:[self comboBoxCellWithTag:0]];
    [[headersTable tableColumnWithIdentifier:@"headerValue"] setDataCell:[self comboBoxCellWithTag:1]];
    //[headersTable setIntercellSpacing:NSMakeSize(3, 3)];
}


- (void)setupBodyTextView {
    [bodyTextView setFont:[self miniSystemFont]];
}


- (NSFont *)miniSystemFont {
    return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
}


- (NSComboBoxCell *)comboBoxCellWithTag:(int)tag {
    NSComboBoxCell *cbCell = [[[NSComboBoxCell alloc] init] autorelease];
    [cbCell setEditable:YES];
    [cbCell setFocusRingType:NSFocusRingTypeNone];
    [cbCell setControlSize:NSSmallControlSize];
    [cbCell setFont:[self miniSystemFont]];
    [cbCell setUsesDataSource:YES];
    [cbCell setDataSource:self];
    [cbCell setTarget:self];
    [cbCell setAction:@selector(handleComboBoxTextChanged:)];
    [cbCell setTag:tag];
    [cbCell setNumberOfVisibleItems:12];
    [cbCell setCompletes:YES];
    return cbCell;
}


- (NSArray *)methodsWithPrefixInFieldEditor:(NSText *)text {
    NSString *s = [text string];
    if (![s length]) {
        return methods;
    }

    s = [s uppercaseString];
    NSString *prefix = [s substringToIndex:[text selectedRange].location];
    
    NSMutableArray *res = [NSMutableArray array];
    for (NSString *method in methods) {
        if ([method hasPrefix:prefix]) {
            [res addObject:method];
        }
    }
    return res;
}


- (NSArray *)headerNamesWithPrefixInFieldEditor:(NSText *)text {
    NSString *s = [text string];
    if (![s length]) {
        return headerNames;
    }
    
    NSString *prefix = [s substringToIndex:[text selectedRange].location];
    return [self headerNamesWithPrefix:prefix];
}


- (NSArray *)headerNamesWithPrefix:(NSString *)s {
    NSMutableArray *res = [NSMutableArray array];
    s = [s lowercaseString];
    for (NSString *hname in headerNames) {
        if ([[hname lowercaseString] hasPrefix:s]) {
            [res addObject:hname];
        }
    }
    return res;
}


- (void)handleComboBoxTextChanged:(id)sender {
    NSInteger col = [sender clickedColumn];
    NSInteger row = [sender clickedRow];
    NSMutableDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
    
    //NSLog(@"row: %i, col: %i",rowIndex,colIndex);
    if (0 == col) { // name changed
        [header setObject:[sender stringValue] forKey:@"name"];
    } else { // value changed
        [header setObject:[sender stringValue] forKey:@"value"];
    }
    
    // if Content-type: multipart/form-data was chosen, we must do some special mutipartformdata-y stuff
    NSTableView *tv = (NSTableView *)sender;
    NSTableColumn *column = [[tv tableColumns] objectAtIndex:col];
    NSString *name  = [[column dataCellForRow:row] stringValue];
    NSString *value = [[column dataCellForRow:row] stringValue];
    
    if ([[name lowercaseString] isEqualToString:@"content-type"]) {
        if ([[value lowercaseString] isEqualToString:@"multipart/form-data"]) {
            [self showMultipartBodyView:self];
        } else {
            [self showNormalBodyView:self];
        }
    }
}


- (BOOL)isNameRequiringTodaysDateString:(NSString *)name {
    return [name isEqualToString:@"if-modified-since"] 
        || [name isEqualToString:@"if-unmodified-since"] 
        || [name isEqualToString:@"if-range"];
}


- (NSString *)todaysDateString {
    NSCalendarDate *today = [NSCalendarDate date];
    // format: Sun, 06 Nov 1994 08:49:37 GMT
    [today setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [today descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT"];
}


- (void)changeSizeForBody {
    CGFloat winHeight = [[self window] frame].size.height;
    NSRect tabFrame = [tabView frame];
    if (bodyShown) {
        tabFrame.size.height = winHeight - 308.0;
    } else {
        tabFrame.size.height = winHeight - 206.0;
    }
    [tabView setFrame:tabFrame];
    [tabView setNeedsDisplay:YES];    
}


- (void)renderGutters {
    [requestTextView renderGutter];
    [responseTextView renderGutter];
}


- (void)updateTextWrapInTextView:(NSTextView *)textView withinScrollView:(NSScrollView *)scrollView {
    BOOL wrap = [[NSUserDefaults standardUserDefaults] boolForKey:HCWrapRequestResponseTextKey];
    
    if (wrap) {
        NSSize s = [scrollView bounds].size;
        s.height = [[textView textContainer] containerSize].height;
        [scrollView setHasHorizontalScroller:NO];
        [[textView textContainer] setContainerSize:s];
        s.width -= 15.; // subtract for width of vert scroll gutter? neccesary to prevent annoying slight horz scrolling
        [textView setFrameSize:s];
        [[textView textContainer] setWidthTracksTextView:YES];
        [textView setHorizontallyResizable:NO];
    } else {
        [scrollView setHasHorizontalScroller:YES];
        [textView setHorizontallyResizable:YES];
        [[textView textContainer] setContainerSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
        [[textView textContainer] setWidthTracksTextView:NO];
        [textView setMaxSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
    }

    NSRange r = NSMakeRange(0, textView.string.length);
    [[[textView textContainer] layoutManager] invalidateDisplayForCharacterRange:r];
    [textView setNeedsDisplay:YES];
}


- (BOOL)isSyntaxHighlightOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:HCSyntaxHighlightRequestResponseTextKey];
}


- (NSAttributedString *)attributedStringForString:(NSString *)s {
    if ([self isSyntaxHighlightOn]) {
        return [syntaxHighlighter attributedStringForString:s];
    } else {
        id attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSColor blackColor], NSForegroundColorAttributeName,
                    [NSFont fontWithName:@"Monaco" size:11.], NSFontAttributeName,
                    nil];
        return [[[NSAttributedString alloc] initWithString:s attributes:attrs] autorelease];
    }
}


- (void)updateSoureCodeViews {
    if (command) {
        NSString *rawRequest = [command objectForKey:@"rawRequest"];
        if (rawRequest.length) {
            self.highlightedRawRequest = [self attributedStringForString:rawRequest];
        }
        NSString *rawResponse = [command objectForKey:@"rawResponse"];
        if (rawResponse.length) {
            self.highlightedRawResponse = [self attributedStringForString:rawResponse];
        }
    }

    NSColor *bgColor = [self isSyntaxHighlightOn] ? [NSColor colorWithDeviceRed:30./255. green:30./255. blue:36./255. alpha:1.] : [NSColor whiteColor];
    NSColor *ipColor = [self isSyntaxHighlightOn] ? [NSColor whiteColor] : [NSColor blackColor];
    
    [requestTextView setBackgroundColor:bgColor];
    [responseTextView setBackgroundColor:bgColor];
    [requestTextView setInsertionPointColor:ipColor];
    [responseTextView setInsertionPointColor:ipColor];
}


// trim out the user-friendly UA names in any user-agent string header values
- (void)cleanUserAgentStringsInHeaders:(NSArray *)headers {
    for (id headerDict in headers) {
        if (NSOrderedSame == [[headerDict objectForKey:@"name"] caseInsensitiveCompare:@"user-agent"]) {
            NSString *value = [headerDict objectForKey:@"value"];
            NSString *marker = @" --- ";
            NSRange r = [value rangeOfString:marker];
            if (NSNotFound != r.location) {
                value = [value substringFromIndex:r.location + marker.length];
                [headerDict setObject:value forKey:@"value"];
            }
        }
    }
}


- (void)requestCompleted:(id)cmd {
    if ([[command objectForKey:@"followRedirects"] boolValue]) {
        [URLComboBox setStringValue:[cmd objectForKey:@"finalURLString"]];
    }
    
    self.command = cmd;
    [self updateSoureCodeViews];
    [self renderGutters];
    self.busy = NO;
    [self openLocation:self]; // focus the url bar    
}


#pragma mark -
#pragma mark HTTPServiceDelegate

- (void)HTTPService:(id <HTTPService>)service didRecieveResponse:(NSString *)rawResponse forRequest:(id)cmd {
    [self playSuccessSound];
	[[HCHistoryManager instance] add:[cmd objectForKey:@"finalURLString"]];
    [self requestCompleted:cmd];
}


- (void)HTTPService:(id <HTTPService>)service request:(id)cmd didFail:(NSString *)msg {
    [self playErrorSound];
    [self requestCompleted:cmd];
}


#pragma mark -
#pragma mark NSControlDelegate

// Invoked when search combobox contents changes. Tells combox box to reload items in popup menu.
- (void)controlTextDidChange:(NSNotification *)n {
    id obj = [n object];
    if ([obj isKindOfClass:[NSTableView class]]) {
        NSTableView *tv = (NSTableView *)obj;
        obj = [[tv tableColumnWithIdentifier:@"headerName"] dataCellForRow:[tv selectedRow]];
    }
    
    // easy cheezy with NSComboBoxes
    if ([obj isKindOfClass:[NSComboBox class]]) {
        [obj noteNumberOfItemsChanged];
        
    // for some reason we have to be more brute-force with NSComboBoxCell :|
    } else if ([obj isKindOfClass:[NSComboBoxCell class]]) {
        [obj noteNumberOfItemsChanged];
        [obj reloadData];
    }
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)cb {
    if (cb == methodComboBox) {
        return [[self methodsWithPrefixInFieldEditor:[cb currentEditor]] count];
    } else {
        return [[HCHistoryManager instance] count];
    }
}


- (id)comboBox:(NSComboBox *)cb objectValueForItemAtIndex:(NSInteger)index {
    if (cb == methodComboBox) {
        return [[self methodsWithPrefixInFieldEditor:[cb currentEditor]] objectAtIndex:index];
    } else {
        return [[HCHistoryManager instance] objectAtIndex:index];    
    }
}


- (NSString *)comboBox:(NSComboBox *)cb completedString:(NSString *)s {
    if (cb == methodComboBox) {
        NSArray *res = [self methodsWithPrefixInFieldEditor:[cb currentEditor]];
        if ([res count]) {
            return [res objectAtIndex:0];
        }
    }
    return nil;
}


#pragma mark -
#pragma mark NSComboBoxCellDataSource

- (id)comboBoxCell:(NSComboBoxCell *)cell objectValueForItemAtIndex:(NSInteger)index {
    BOOL isValueCell = [cell tag];
    if (isValueCell) {
        NSDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
        NSString *name = [[header objectForKey:@"name"] lowercaseString];
        
        if ([self isNameRequiringTodaysDateString:name]) {
            return [self todaysDateString];
        } else {
            return [[headerValues objectForKey:name] objectAtIndex:index];
        }
    } else {
        NSText *text = [[self window] fieldEditor:NO forObject:cell];
        return [[self headerNamesWithPrefixInFieldEditor:text] objectAtIndex:index];
    }
}


- (NSInteger)numberOfItemsInComboBoxCell:(NSComboBoxCell *)cell {
    BOOL isValueCell = [cell tag];
    if (isValueCell) {
        NSDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
        NSString *name = [[header objectForKey:@"name"] lowercaseString];
        
        if ([self isNameRequiringTodaysDateString:name]) {
            return 1;
        } else {
            return [[headerValues objectForKey:name] count];
        }
    } else {
        NSText *text = [[self window] fieldEditor:NO forObject:cell];
        return [[self headerNamesWithPrefixInFieldEditor:text] count];
    }
}


- (NSString *)comboBoxCell:(NSComboBoxCell *)cell completedString:(NSString *)s {
    BOOL isValueCell = [cell tag];
    if (isValueCell) {
        NSDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
        NSString *name = [[header objectForKey:@"name"] lowercaseString];
        
        NSArray *values = [headerValues objectForKey:name];
        s = [s lowercaseString];
        for (NSString *value in values) {
            if ([[value lowercaseString] hasPrefix:s]) {
                return value;
            }
        }
        return nil;
    } else {
        NSArray *names = [self headerNamesWithPrefix:s];
        if ([names count]) {
            return [names objectAtIndex:0];
        } else {
            return nil;
        }
    }
}

                 
#pragma mark -
#pragma mark NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [self renderGutters];
}


#pragma mark -
#pragma mark Accessors

- (void)setBodyShown:(BOOL)yn {
    [self willChangeValueForKey:@"bodyShown"];
    bodyShown = yn;
    [self changeSizeForBody];
    [[self document] updateChangeCount:NSChangeDone];
    [self didChangeValueForKey:@"bodyShown"];
}


- (void)setCommand:(id)c {
    if (command != c) {
        [command autorelease];
        command = [c retain];
        
        [command addObserver:self forKeyPath:@"URLString" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"body" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"method" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"followRedirects" options:NSKeyValueObservingOptionNew context:NULL];
    }
}


- (void)setAttachedFilePath:(NSString *)s {
    if (s != attachedFilePath) {
        [self willChangeValueForKey:@"attachedFilePath"];
        
        [attachedFilePath autorelease];
        attachedFilePath = [s retain];

        self.attachedFilename = [s lastPathComponent];
        
        [[self document] updateChangeCount:NSChangeDone];
        [self didChangeValueForKey:@"attachedFilePath"];
    }
}

@synthesize service;
@synthesize headersController;
@synthesize command;
@synthesize highlightedRawRequest;
@synthesize highlightedRawResponse;
@synthesize busy;
@synthesize bodyShown;
@synthesize methods;
@synthesize headerNames;
@synthesize headerValues;
@synthesize multipartBodyShown;
@synthesize attachedFilePath;
@synthesize attachedFilename;
@synthesize syntaxHighlighter;
@synthesize authUsername;
@synthesize authPassword;
@synthesize authMessage;
@synthesize rememberAuthPassword;
@end
