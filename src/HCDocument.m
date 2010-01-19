//
//  HCDocument.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCDocument.h"
#import "HCWindowController.h"

@interface HCDocument ()
@property (nonatomic, retain) NSDictionary *config;
@end

@implementation HCDocument

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


- (void)dealloc {
    self.windowController = nil;
	self.config = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument

- (void)makeWindowControllers {
	self.windowController = [[[HCWindowController alloc] init] autorelease];

	if (config) {
		[[windowController window] setFrameFromString:[config objectForKey:@"windowFrameString"]];
		windowController.bodyShown = [[config objectForKey:@"bodyShown"] boolValue];
		windowController.multipartBodyShown = [[config objectForKey:@"multipartBodyShown"] boolValue];
		windowController.command = [config objectForKey:@"command"];
		[windowController.headersController addObjects:[config objectForKey:@"headers"]];
		self.config = nil;
	}
	
    [self addWindowController:windowController];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *result = nil;
    @try {
        id dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setObject:[[windowController window] stringWithSavedFrame] forKey:@"windowFrameString"];
        [dict setObject:[NSNumber numberWithBool:windowController.isBodyShown] forKey:@"bodyShown"];
        [dict setObject:[NSNumber numberWithBool:windowController.isMultipartBodyShown] forKey:@"multipartBodyShown"];
        
        id cmd = [NSMutableDictionary dictionaryWithDictionary:windowController.command];
        [cmd setObject:@"" forKey:@"rawRequest"];
        [cmd setObject:@"" forKey:@"rawResponse"];
        
        [dict setObject:cmd forKey:@"command"];
        [dict setObject:[windowController.headersController arrangedObjects] forKey:@"headers"];
        
        result = [NSKeyedArchiver archivedDataWithRootObject:dict];
        if (!result) [NSException raise:@"UnknownError" format:nil];
    } @catch (NSException *e) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:writErr userInfo:[e userInfo]];
    }
    return result;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result = YES;
    @try {
        self.config = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (!config) [NSException raise:@"UnknownError" format:nil];
    } @catch (NSException *e) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:readErr userInfo:[e userInfo]];
        result = NO;
    }
    return result;
}

@synthesize windowController;
@synthesize config;
@end
