//
//  HCWindowController.h
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol HTTPService;
@class TDSourceCodeTextView;
@class TDHtmlSyntaxHighlighter;

@interface HCWindowController : NSWindowController {
    IBOutlet NSComboBox *URLComboBox;
    IBOutlet NSComboBox *methodComboBox;
    IBOutlet NSTableView *headersTable;
    IBOutlet NSTextView *bodyTextView;
    IBOutlet NSTabView *tabView;
    IBOutlet TDSourceCodeTextView *requestTextView;
    IBOutlet TDSourceCodeTextView *responseTextView;
    IBOutlet NSScrollView *requestScrollView;
    IBOutlet NSScrollView *responseScrollView;
    IBOutlet NSArrayController *headersController;
    id <HTTPService>service;
    
    NSMutableDictionary *command;
    NSAttributedString *highlightedRawRequest;
    NSAttributedString *highlightedRawResponse;
    BOOL busy;
    BOOL bodyShown;
    
    NSArray *methods;
    NSArray *headerNames;
    NSDictionary *headerValues;

    BOOL multipartBodyShown;
    NSString *attachedFilePath;
    NSString *attachedFilename;
    
    TDHtmlSyntaxHighlighter *syntaxHighlighter;
    
    // HTTPAuth
    IBOutlet NSPanel *httpAuthSheet;
    IBOutlet NSTextField *authUsernameTextField;
    IBOutlet NSTextField *authPasswordTextField;
    
    NSString *authUsername;
    NSString *authPassword;
    NSString *authMessage;
    BOOL rememberAuthPassword;    
}
- (IBAction)openLocation:(id)sender;
- (IBAction)historyMenuItemAction:(id)sender;
- (IBAction)execute:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)showRequest:(id)sender;
- (IBAction)showResponse:(id)sender;
- (IBAction)showMultipartBodyView:(id)sender;
- (IBAction)showNormalBodyView:(id)sender;
- (IBAction)runAttachFileSheet:(id)sender;

@property (nonatomic, retain) id <HTTPService>service;
@property (nonatomic, retain) NSArrayController *headersController;

@property (nonatomic, retain) id command;
@property (nonatomic, copy) NSAttributedString *highlightedRawRequest;
@property (nonatomic, copy) NSAttributedString *highlightedRawResponse;

@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, getter=isBodyShown) BOOL bodyShown;

@property (nonatomic, retain) NSArray *methods;
@property (nonatomic, retain) NSArray *headerNames;
@property (nonatomic, retain) NSDictionary *headerValues;

@property (nonatomic, getter=isMultipartBodyShown) BOOL multipartBodyShown;
@property (nonatomic, retain) NSString *attachedFilePath;
@property (nonatomic, retain) NSString *attachedFilename;

@property (nonatomic, retain) TDHtmlSyntaxHighlighter *syntaxHighlighter;

@property (nonatomic, copy) NSString *authUsername;
@property (nonatomic, copy) NSString *authPassword;
@property (nonatomic, copy) NSString *authMessage;
@property (nonatomic) BOOL rememberAuthPassword;
@end