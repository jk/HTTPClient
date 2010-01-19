//
//  TDHtmlSyntaxHighlighter.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 8/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TDHtmlSyntaxHighlighter.h"
#import <TDParseKit/TDParseKit.h>

@interface NSArray (TDHtmlSyntaxHighlighterAdditions)
- (NSMutableArray *)reversedMutableArray;
@end

@implementation NSArray (TDHtmlSyntaxHighlighterAdditions)

- (NSMutableArray *)reversedMutableArray {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    NSEnumerator *e = [self reverseObjectEnumerator];
    id obj = nil;
    while (obj = [e nextObject]) {
        [result addObject:obj];
    }
    return result;
}

@end

@interface TDHtmlSyntaxHighlighter ()
- (void)workOnTag;
- (void)workOnText;
- (void)workOnComment;
- (void)workOnCDATA;
- (void)workOnPI;
- (void)workOnDoctype;
- (void)workOnScript;
- (id)peek;
- (id)pop;
- (NSArray *)objectsAbove:(id)fence;
- (TDToken *)nextNonWhitespaceTokenFrom:(NSEnumerator *)e;
- (void)consumeWhitespaceOnStack;

@property (retain) TDTokenizer *tokenizer;
@property (retain) NSMutableArray *stack;
@property (retain) TDToken *ltToken;
@property (retain) TDToken *gtToken;
@property (retain) TDToken *startCommentToken;
@property (retain) TDToken *endCommentToken;
@property (retain) TDToken *startCDATAToken;
@property (retain) TDToken *endCDATAToken;
@property (retain) TDToken *startPIToken;
@property (retain) TDToken *endPIToken;
@property (retain) TDToken *startDoctypeToken;
@property (retain) TDToken *fwdSlashToken;
@property (retain) TDToken *eqToken;
@property (retain) TDToken *scriptToken;
@property (retain) TDToken *endScriptToken;
@end

@implementation TDHtmlSyntaxHighlighter

- (id)init {
    return [self initWithAttributesForDarkBackground:NO];
}


- (id)initWithAttributesForDarkBackground:(BOOL)isDark {
    self = [super init];
    if (self) {
        isDarkBG = isDark;
        
        self.tokenizer = [TDTokenizer tokenizer];

        // configure tokenizer
        [tokenizer setTokenizerState:tokenizer.symbolState from:'/' to:'/']; // HTML doesn't have slash slash or slash star comments
        tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
        [tokenizer.wordState setWordChars:YES from:':' to:':'];
        
        self.ltToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"<" floatValue:0.0f];
        self.gtToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@">" floatValue:0.0f];
        
        self.startCommentToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"<!--" floatValue:0.0f];
        self.endCommentToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"-->" floatValue:0.0f];
        [tokenizer.symbolState add:startCommentToken.stringValue];
        [tokenizer.symbolState add:endCommentToken.stringValue];
        
        self.startCDATAToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"<![CDATA[" floatValue:0.0f];
        self.endCDATAToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"]]>" floatValue:0.0f];
        [tokenizer.symbolState add:startCDATAToken.stringValue];
        [tokenizer.symbolState add:endCDATAToken.stringValue];
        
        self.startPIToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"<?" floatValue:0.0f];
        self.endPIToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"?>" floatValue:0.0f];
        [tokenizer.symbolState add:startPIToken.stringValue];
        [tokenizer.symbolState add:endPIToken.stringValue];
        
        self.startDoctypeToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"<!DOCTYPE" floatValue:0.0f];
        [tokenizer.symbolState add:startDoctypeToken.stringValue];
        
        self.fwdSlashToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"/" floatValue:0.0f];
        self.eqToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"=" floatValue:0.0f];
        
        self.scriptToken = [TDToken tokenWithTokenType:TDTokenTypeWord stringValue:@"script" floatValue:0.0f];
        
        self.endScriptToken = gtToken;
        //        self.endScriptToken = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"</script>" floatValue:0.0f];
        //        [tokenizer.symbolState add:endScriptToken.stringValue];
        
        NSFont *monacoFont = [NSFont fontWithName:@"Monaco" size:11.];
        
        NSColor *textColor = nil;
        NSColor *tagColor = nil;
        NSColor *attrNameColor = nil;
        NSColor *attrValueColor = nil;
        NSColor *eqColor = nil;
        NSColor *commentColor = nil;
        NSColor *piColor = nil;
        
        if (isDarkBG) {
            textColor = [NSColor whiteColor];
            tagColor = [NSColor colorWithDeviceRed:.70 green:.14 blue:.53 alpha:1.];
            attrNameColor = [NSColor colorWithDeviceRed:.33 green:.45 blue:.48 alpha:1.];
            attrValueColor = [NSColor colorWithDeviceRed:.77 green:.18 blue:.20 alpha:1.];
            eqColor = tagColor;
            commentColor = [NSColor colorWithDeviceRed:.24 green:.70 blue:.27 alpha:1.];
            piColor = [NSColor colorWithDeviceRed:.09 green:.62 blue:.74 alpha:1.];
        } else {
            textColor = [NSColor blackColor];
            tagColor = [NSColor purpleColor];
            attrNameColor = [NSColor colorWithDeviceRed:0. green:0. blue:.75 alpha:1.];
            attrValueColor = [NSColor colorWithDeviceRed:.75 green:0. blue:0. alpha:1.];
            eqColor = [NSColor darkGrayColor];
            commentColor = [NSColor grayColor];
            piColor = [NSColor colorWithDeviceRed:.09 green:.62 blue:.74 alpha:1.];
        }
        
        self.headerNameAttributes   = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrNameColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.headerValueAttributes  = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrValueColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.textAttributes         = [NSDictionary dictionaryWithObjectsAndKeys:
                                       textColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.tagAttributes          = [NSDictionary dictionaryWithObjectsAndKeys:
                                       tagColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.attrNameAttributes     = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrNameColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.attrValueAttributes    = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrValueColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.eqAttributes           = [NSDictionary dictionaryWithObjectsAndKeys:
                                       eqColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.commentAttributes      = [NSDictionary dictionaryWithObjectsAndKeys:
                                       commentColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.piAttributes           = [NSDictionary dictionaryWithObjectsAndKeys:
                                       piColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
    }
    return self;
}


- (void)dealloc {
    self.tokenizer = nil;
    self.stack = nil;
    self.ltToken = nil;
    self.gtToken = nil;
    self.startCommentToken = nil;
    self.endCommentToken = nil;
    self.startCDATAToken = nil;
    self.endCDATAToken = nil;
    self.startPIToken = nil;
    self.endPIToken = nil;
    self.startDoctypeToken = nil;
    self.fwdSlashToken = nil;
    self.eqToken = nil;
    self.scriptToken = nil;
    self.endScriptToken = nil;
    self.highlightedString = nil;
    self.headerNameAttributes = nil;
    self.headerValueAttributes = nil;
    self.textAttributes = nil;
    self.tagAttributes = nil;
    self.attrNameAttributes = nil;
    self.attrValueAttributes = nil;
    self.eqAttributes = nil;
    self.commentAttributes = nil;
    self.piAttributes = nil;
    [super dealloc];
}


- (void)parseHeaders:(NSString *)s {
    NSAttributedString *as = nil;
    NSArray *lines = [s componentsSeparatedByString:@"\r\n"];
    for (NSString *line in lines) {
        NSRange r = [line rangeOfString:@":"];
        if (NSNotFound == r.location) { // handle response status line or malformed header
            line = [NSString stringWithFormat:@"%@\r\n", line];
            as = [[NSAttributedString alloc] initWithString:line attributes:textAttributes];
            [highlightedString appendAttributedString:as];
            [as release];
        } else {
            NSInteger i = r.location + 1;
            NSString *name = [line substringToIndex:i];
            NSString *value = [NSString stringWithFormat:@"%@\r\n", [line substringFromIndex:i]];
            as = [[NSAttributedString alloc] initWithString:name attributes:headerNameAttributes];
            [highlightedString appendAttributedString:as];
            [as release];
            as = [[NSAttributedString alloc] initWithString:value attributes:headerValueAttributes];
            [highlightedString appendAttributedString:as];
            [as release];
        }
    }
    as = [[NSAttributedString alloc] initWithString:@"\r\n" attributes:textAttributes];
    [highlightedString appendAttributedString:as];
    [as release];
}


- (NSAttributedString *)attributedStringForString:(NSString *)s {
    self.stack = [NSMutableArray array];
    self.highlightedString = [[[NSMutableAttributedString alloc] init] autorelease];
    
    NSRange r = [s rangeOfString:@"\r\n\r\n"];
    if (NSNotFound != r.location) {
        [self parseHeaders:[s substringToIndex:r.location]];
        s = [s substringFromIndex:r.location + r.length];
    }
    NSInteger lengthOfHeaders = highlightedString.length;
    
    tokenizer.string = s;
    TDToken *eof = [TDToken EOFToken];
    TDToken *tok = nil;
    BOOL inComment = NO;
    BOOL inCDATA = NO;
    BOOL inPI = NO;
    BOOL inDoctype = NO;
    
    while ((tok = [tokenizer nextToken]) != eof) {    
        
        if (!inComment && !inCDATA && !inPI && !inDoctype && !inScript && tok.isSymbol) {
            if ([startCommentToken isEqual:tok]) {
                [stack addObject:tok];
                inComment = YES;
            } else if ([startCDATAToken isEqual:tok]) {
                [stack addObject:tok];
                inCDATA = YES;
            } else if ([startPIToken isEqual:tok]) {
                [stack addObject:tok];
                inPI = YES;
            } else if ([startDoctypeToken isEqual:tok]) {
                [stack addObject:tok];
                inDoctype = YES;
            } else if ([ltToken isEqual:tok]) {
                [self workOnText];
                [stack addObject:tok];
            } else if ([gtToken isEqual:tok]) {
                [stack addObject:tok];
                [self workOnTag];
            } else {
                [stack addObject:tok];
            }
        } else if (inComment && [endCommentToken isEqual:tok]) {
            inComment = NO;
            [stack addObject:tok];
            [self workOnComment];
        } else if (inCDATA && [endCDATAToken isEqual:tok]) {
            inCDATA = NO;
            [stack addObject:tok];
            [self workOnCDATA];
        } else if (inPI && [endPIToken isEqual:tok]) {
            inPI = NO;
            [stack addObject:tok];
            [self workOnPI];
        } else if (inDoctype && [gtToken isEqual:tok]) {
            inDoctype = NO;
            [stack addObject:tok];
            [self workOnDoctype];
        } else if (inScript && [endScriptToken isEqual:tok]) {
            inScript = NO;
            [stack addObject:tok];
            [self workOnScript];
        } else {
            [stack addObject:tok];
        }
    }
    
    // handle case where no elements were encountered (plain text basically)
    if (lengthOfHeaders == highlightedString.length && stack.count) {
        for (TDToken *tok in stack) {
            NSAttributedString *as = [[NSAttributedString alloc] initWithString:tok.stringValue attributes:textAttributes];
            [highlightedString appendAttributedString:as];
            [as release];
        }
    }
    
    NSAttributedString *result = [[highlightedString copy] autorelease];
    self.stack = nil;
    self.highlightedString = nil;
    tokenizer.string = nil;
    return result;
}


- (TDToken *)nextNonWhitespaceTokenFrom:(NSEnumerator *)e {
    TDToken *tok = [e nextObject];
    while (tok.isWhitespace) {
        NSAttributedString *as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
        [highlightedString appendAttributedString:as];
        tok = [e nextObject];
    }
    return tok;
}


- (void)consumeWhitespaceOnStack {
    TDToken *tok = [self peek];
    while (tok.isWhitespace) {
        tok = [self pop];
        NSAttributedString *as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
        [highlightedString appendAttributedString:as];
        tok = [self peek];
    }
}


- (void)workOnComment {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:startCommentToken] reversedMutableArray];
    
    [self consumeWhitespaceOnStack];
    
    NSAttributedString *as = [[[NSAttributedString alloc] initWithString:startCommentToken.stringValue attributes:commentAttributes] autorelease];
    [highlightedString appendAttributedString:as];
    
    NSEnumerator *e = [toks objectEnumerator];
    
    TDToken *tok = nil;
    while (tok = [self nextNonWhitespaceTokenFrom:e]) {
        if ([tok isEqual:endCommentToken]) {
            break;
        } else {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:commentAttributes] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
    
    as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:commentAttributes] autorelease];
    [highlightedString appendAttributedString:as];
}


- (void)workOnCDATA {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:startCDATAToken] reversedMutableArray];
    
    [self consumeWhitespaceOnStack];
    
    NSAttributedString *as = [[[NSAttributedString alloc] initWithString:startCDATAToken.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
    
    NSEnumerator *e = [toks objectEnumerator];
    
    TDToken *tok = nil;
    while (tok = [self nextNonWhitespaceTokenFrom:e]) {
        if ([tok isEqual:endCDATAToken]) {
            break;
        } else {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:textAttributes] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
    
    as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
}


- (void)workOnPI {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:startPIToken] reversedMutableArray];
    
    [self consumeWhitespaceOnStack];
    
    NSAttributedString *as = [[[NSAttributedString alloc] initWithString:startPIToken.stringValue attributes:piAttributes] autorelease];
    [highlightedString appendAttributedString:as];
    
    NSEnumerator *e = [toks objectEnumerator];
    
    TDToken *tok = nil;
    while (tok = [self nextNonWhitespaceTokenFrom:e]) {
        if ([tok isEqual:endPIToken]) {
            break;
        } else {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:piAttributes] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
    
    as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:piAttributes] autorelease];
    [highlightedString appendAttributedString:as];
}


- (void)workOnDoctype {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:startDoctypeToken] reversedMutableArray];
    
    [self consumeWhitespaceOnStack];
    
    NSAttributedString *as = [[[NSAttributedString alloc] initWithString:startDoctypeToken.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
    
    NSEnumerator *e = [toks objectEnumerator];
    
    TDToken *tok = nil;
    while (tok = [self nextNonWhitespaceTokenFrom:e]) {
        if ([tok isEqual:gtToken]) {
            break;
        } else {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
    
    as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
}


- (void)workOnScript {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:startDoctypeToken] reversedMutableArray];
    
    NSEnumerator *e = [toks objectEnumerator];
    NSAttributedString *as = nil;
    
    TDToken *tok = nil;
    while (tok = [self nextNonWhitespaceTokenFrom:e]) {
        if ([tok isEqual:endScriptToken]) {
            break;
        } else {
            NSDictionary *attrs = nil;
            if ([tok isEqual:scriptToken] || [tok isEqual:ltToken] || [tok isEqual:fwdSlashToken]) {
                attrs = tagAttributes;
            } else {
                attrs = textAttributes;
            }
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:attrs] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
    
    as = [[[NSAttributedString alloc] initWithString:endScriptToken.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
}


- (void)workOnStartTag:(NSEnumerator *)e {
    while (1) {
        // attr name or ns prefix decl "xmlns:foo" or "/" for empty element
        TDToken *tok = [self nextNonWhitespaceTokenFrom:e];
        if (!tok) return;
        
        NSDictionary *attrs = nil;
        if ([tok isEqual:eqToken]) {
            attrs = eqAttributes;
        } else if ([tok isEqual:fwdSlashToken] || [tok isEqual:gtToken]) {
            attrs = tagAttributes;
        } else if (tok.isQuotedString) {
            attrs = attrValueAttributes;
        } else {
            attrs = attrNameAttributes;
        }

        NSAttributedString *as = nil;
        if (tok.stringValue) {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:attrs] autorelease];
            [highlightedString appendAttributedString:as];
        }
        
        // "="
        tok = [self nextNonWhitespaceTokenFrom:e];
        if (!tok) return;
        
        if ([tok isEqual:eqToken]) {
            attrs = eqAttributes;
        } else if ([tok isEqual:fwdSlashToken] || [tok isEqual:gtToken]) {
            attrs = tagAttributes;
        } else if (tok.isQuotedString) {
            attrs = attrValueAttributes;
        } else {
            attrs = tagAttributes;
        }
        
        if (tok.stringValue) {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:attrs] autorelease];
            [highlightedString appendAttributedString:as];
        }
        
        // quoted string attr value or ns url value
        tok = [self nextNonWhitespaceTokenFrom:e];
        if (!tok) return;
        
        if ([tok isEqual:fwdSlashToken] || [tok isEqual:gtToken]) {
            attrs = tagAttributes;
        } else {
            attrs = attrValueAttributes;
        }
        
        if (tok.stringValue) {
            as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:attrs] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
}


- (void)workOnEndTag:(NSEnumerator *)e {
    // consume tagName to ">"
    TDToken *tok = nil; 
    while (tok = [e nextObject]) {
        NSAttributedString *as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
        [highlightedString appendAttributedString:as];
    }
}


- (void)workOnTag {
    // reverse toks to be in document order
    NSMutableArray *toks = [[self objectsAbove:nil] reversedMutableArray];
    NSAttributedString *as =  nil;
    
    NSEnumerator *e = [toks objectEnumerator];
    
    // append "<"
    [self nextNonWhitespaceTokenFrom:e]; // consume whitespace and discard
    as = [[[NSAttributedString alloc] initWithString:ltToken.stringValue attributes:tagAttributes] autorelease];
    [highlightedString appendAttributedString:as];
    
    // consume whitespace to tagName or "/" for end tags or "!" for comments
    TDToken *tok = [self nextNonWhitespaceTokenFrom:e];
    
    if (tok) {
        
        if ([tok isEqual:scriptToken]) {
            inScript = YES;
        } else {
            inScript = NO;
        }
        
        // consume tagName or "/" or "!"
        as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:tagAttributes] autorelease];
        [highlightedString appendAttributedString:as];
        
        if ([tok isEqual:fwdSlashToken]) {
            [self workOnEndTag:e];
        } else {
            [self workOnStartTag:e];
        }
    }
}


- (void)workOnText {
    NSArray *a = [self objectsAbove:gtToken];
    NSEnumerator *e = [a reverseObjectEnumerator];
    TDToken *tok = nil;
    while (tok = [e nextObject]) {
        NSString *s = tok.stringValue;
        if (s) {
            NSAttributedString *as = [[[NSAttributedString alloc] initWithString:tok.stringValue attributes:textAttributes] autorelease];
            [highlightedString appendAttributedString:as];
        }
    }
}


- (NSArray *)objectsAbove:(id)fence {
    NSMutableArray *res = [NSMutableArray array];
    while (1) {
        if (!stack.count) {
            break;
        }
        id obj = [self pop];
        if ([obj isEqual:fence]) {
            break;
        }
        [res addObject:obj];
    }
    return res;
}


- (id)peek {
    id obj = nil;
    if (stack.count) {
        obj = [stack lastObject];
    }
    return obj;
}


- (id)pop {
    id obj = [self peek];
    if (obj) {
        [stack removeLastObject];
    }
    return obj;
}

@synthesize stack;
@synthesize tokenizer;
@synthesize ltToken;
@synthesize gtToken;
@synthesize startCommentToken;
@synthesize endCommentToken;
@synthesize startCDATAToken;
@synthesize endCDATAToken;
@synthesize startPIToken;
@synthesize endPIToken;
@synthesize startDoctypeToken;
@synthesize fwdSlashToken;
@synthesize eqToken;
@synthesize scriptToken;
@synthesize endScriptToken;
@synthesize highlightedString;
@synthesize headerNameAttributes;
@synthesize headerValueAttributes;
@synthesize textAttributes;
@synthesize tagAttributes;
@synthesize attrNameAttributes;
@synthesize attrValueAttributes;
@synthesize eqAttributes;
@synthesize commentAttributes;
@synthesize piAttributes;
@end
