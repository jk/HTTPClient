//
//  TDSyntaxHighlightController.h
//  HTTPClient
//
//  Created by Todd Ditchendorf on 12/26/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDParser;
@class TDTokenizer;
@class TDGrammarParserFactory;
@class TDMiniCSSAssembler;
@class TDGenericAssembler;

@interface TDSyntaxHighlightController : NSObject {
    TDGrammarParserFactory *parserFactory;
    TDParser *miniCSSParser;
    TDMiniCSSAssembler *miniCSSAssembler;
    TDGenericAssembler *genericAssembler;
    BOOL cacheParsers;
    NSMutableDictionary *parserCache;
    TDTokenizer *tokenizer;
}
- (NSAttributedString *)highlightedStringForString:(NSString *)s ofGrammar:(NSString *)grammarName;

@property (nonatomic) BOOL cacheParsers; // default is NO
@end
