//
//  TDCharbufState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 7/14/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TDParseKit/TDTokenizerState.h>

// NOTE: this class is not currently in use or included in the Framework. Using TDMutableStringState instead

// Abstract Class
@interface TDCharbufState : TDTokenizerState {
    char *__strong charbuf;
    NSInteger len;
}

- (void)reset;
- (void)checkBufLength:(NSInteger)i;
- (char *)mallocCharbuf:(NSInteger)size;
@end
