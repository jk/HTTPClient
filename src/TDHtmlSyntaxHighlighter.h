//
//  TDHtmlSyntaxHighlighter.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 8/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDTokenizer;
@class TDToken;

@interface TDHtmlSyntaxHighlighter : NSObject {
    BOOL isDarkBG;
    BOOL inScript;
    TDTokenizer *tokenizer;
    NSMutableArray *stack;
    TDToken *ltToken;
    TDToken *gtToken;
    TDToken *startCommentToken;
    TDToken *endCommentToken;
    TDToken *startCDATAToken;
    TDToken *endCDATAToken;
    TDToken *startPIToken;
    TDToken *endPIToken;
    TDToken *startDoctypeToken;
    TDToken *fwdSlashToken;
    TDToken *eqToken;
    TDToken *scriptToken;
    TDToken *endScriptToken;
    
    NSMutableAttributedString *highlightedString;
    NSDictionary *headerNameAttributes;
    NSDictionary *headerValueAttributes;
    NSDictionary *textAttributes;
    NSDictionary *tagAttributes;
    NSDictionary *attrNameAttributes;
    NSDictionary *attrValueAttributes;
    NSDictionary *eqAttributes;
    NSDictionary *commentAttributes;
    NSDictionary *piAttributes;
}
- (id)initWithAttributesForDarkBackground:(BOOL)isDark;

- (NSAttributedString *)attributedStringForString:(NSString *)s;

@property (nonatomic, retain) NSMutableAttributedString *highlightedString;
@property (nonatomic, retain) NSDictionary *headerNameAttributes;
@property (nonatomic, retain) NSDictionary *headerValueAttributes;
@property (nonatomic, retain) NSDictionary *textAttributes;
@property (nonatomic, retain) NSDictionary *tagAttributes;
@property (nonatomic, retain) NSDictionary *attrNameAttributes;
@property (nonatomic, retain) NSDictionary *attrValueAttributes;
@property (nonatomic, retain) NSDictionary *eqAttributes;
@property (nonatomic, retain) NSDictionary *commentAttributes;
@property (nonatomic, retain) NSDictionary *piAttributes;
@end
