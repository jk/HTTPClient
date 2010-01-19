//
//  HTTPServiceCFNetworkImpl.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HTTPServiceCFNetworkImpl.h"

#define BUFSIZE 1024

@interface HTTPServiceCFNetworkImpl ()
- (void)doSendHTTPRequest;
- (NSString *)makeHTTPRequestWithURL:(NSURL *)URL 
                              method:(NSString *)method 
                                body:(NSString *)body 
                             headers:(NSArray *)headers 
                     followRedirects:(BOOL)followRedirects 
                   getFinalURLString:(NSString **)outFinalURLString;

- (CFHTTPMessageRef)copyHTTPRequestWithURL:(NSURL *)URL method:(NSString *)method body:(NSString *)body headers:(NSArray *)headers;
- (CFHTTPMessageRef)copyResponseBySendingHTTPRequest:(CFHTTPMessageRef)req followRedirects:(BOOL)followRedirects;
- (NSString *)rawStringForHTTPMessage:(CFHTTPMessageRef)message;
- (NSStringEncoding)stringEncodingForBodyOfHTTPMessage:(CFHTTPMessageRef)message;

- (void)success:(NSString *)rawResponse;
- (void)doSuccess:(NSString *)rawResponse;
- (void)failure:(NSString *)msg;
- (void)doFailure:(NSString *)msg;
@end

static BOOL isAuthChallengeForProxyStatusCode(NSInteger statusCode) {
    return (407 == statusCode);
}


static BOOL isAuthChallengeStatusCode(NSInteger statusCode) {
    return (401 == statusCode || isAuthChallengeForProxyStatusCode(statusCode));
}

@implementation HTTPServiceCFNetworkImpl

#pragma mark -
#pragma mark HTTPClientHTTPService

- (id)initWithDelegate:(id)d {
    self = [super init];
    if (self) {
        self.delegate = d;
    }
    return self;
}


- (void)dealloc; {
    //self.delegate = nil; // clang no likie
    delegate = nil;
    self.command = nil;
    self.authUsername = nil;
    self.authPassword = nil;
    [super dealloc];
}


- (void)sendHTTPRequest:(id)cmd {
    self.command = cmd;
    [NSThread detachNewThreadSelector:@selector(doSendHTTPRequest) toTarget:self withObject:nil];
}


#pragma mark -
#pragma mark Private

- (void)doSendHTTPRequest {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *URLString = [[command objectForKey:@"URLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSString *method = [command objectForKey:@"method"];
    NSString *body = [command objectForKey:@"body"];
    NSArray *headers = [command objectForKey:@"headers"];
    BOOL followRedirects = [[command objectForKey:@"followRedirects"] boolValue];
    
    NSString *finalURLString = nil;
    NSString *rawResponse = [self makeHTTPRequestWithURL:URL method:method body:body headers:headers followRedirects:followRedirects getFinalURLString:&finalURLString];
    
    if (finalURLString.length) {
        [command setObject:finalURLString forKey:@"finalURLString"];
    }
    
    if (!rawResponse.length) {
        NSString *s = @"(( Zero-length response returned from server. ))";
        [command setObject:s forKey:@"rawResponse"];
        NSLog(s);
        [self failure:s];
    } else {
        [command setObject:rawResponse forKey:@"rawResponse"];
        [self success:rawResponse];
    }
    
    [pool release];
}


- (NSString *)makeHTTPRequestWithURL:(NSURL *)URL method:(NSString *)method body:(NSString *)body headers:(NSArray *)headers followRedirects:(BOOL)followRedirects getFinalURLString:(NSString **)outFinalURLString {
    NSString *result = nil;
    CFHTTPMessageRef request = [self copyHTTPRequestWithURL:URL method:method body:body headers:headers];
    CFHTTPMessageRef response = NULL;
    CFHTTPAuthenticationRef auth = NULL;
    NSInteger count = 0;
    
    while (1) {
        //    send request
        response = [self copyResponseBySendingHTTPRequest:request followRedirects:followRedirects];
        
        if (!response) {
            result = nil;
            break;
        }
        
        NSURL *finalURL = (NSURL *)CFHTTPMessageCopyRequestURL(response);
        (*outFinalURLString) = [finalURL absoluteString];
        [finalURL release];
        NSInteger responseStatusCode = CFHTTPMessageGetResponseStatusCode(response);
        
        if (!isAuthChallengeStatusCode(responseStatusCode)) {
            result = [self rawStringForHTTPMessage:response];
            break;
        }
        
        if (count) {
            self.authUsername = nil;
            self.authPassword = nil;
        }
        
        BOOL forProxy = isAuthChallengeForProxyStatusCode(responseStatusCode);
        auth = CFHTTPAuthenticationCreateFromResponse(kCFAllocatorDefault, response);
        
        NSString *scheme = [(id)CFHTTPAuthenticationCopyMethod(auth) autorelease];
        NSString *realm  = [(id)CFHTTPAuthenticationCopyRealm(auth) autorelease];
        NSArray *domains = [(id)CFHTTPAuthenticationCopyDomains(auth) autorelease];
        NSURL *domain = domains.count ? [domains objectAtIndex:0] : nil;
        
        BOOL cancelled = NO;
        NSString *username = nil;
        NSString *password = nil;
        
        // try the previous username/password first? do we really wanna do that?
        if (0 == count && self.authUsername.length && self.authPassword.length) {
            username = self.authUsername;
            password = self.authPassword;
        } 
        cancelled = [delegate getUsername:&username password:&password forAuthScheme:scheme URL:URL realm:realm domain:domain forProxy:forProxy isRetry:count];
        count++;
        
        self.authUsername = username;
        self.authPassword = password;
        
        if (cancelled) {
            result = nil;
            break;
        }        
        
        if (request) {
            CFRelease(request);
            request = NULL;
        }
        if (response) {
            CFRelease(response);
            response = NULL;
        }
        
        request = [self copyHTTPRequestWithURL:URL method:method body:body headers:headers];
        
        NSMutableDictionary *creds = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      username,  kCFHTTPAuthenticationUsername,
                                      password,  kCFHTTPAuthenticationPassword,
                                      nil];
        
        if (domain && CFHTTPAuthenticationRequiresAccountDomain(auth)) {
            [creds setObject:[domain absoluteString] forKey:(id)kCFHTTPAuthenticationAccountDomain];
        }
        
        Boolean credentialsApplied = CFHTTPMessageApplyCredentialDictionary(request, auth, (CFDictionaryRef)creds, NULL);
        
        if (auth) {
            CFRelease(auth);
            auth = NULL;
        }
        
        if (!credentialsApplied) {
            NSLog(@"OH BOTHER. Can't add add auth credentials to request. dunno why. FAIL.");
            result = nil;
            break;
        }
    }
    
    if (request) {
        CFRelease(request);
        request = NULL;
    }
    if (response) {
        CFRelease(response);
        response = NULL;
    }
    if (auth) {
        CFRelease(auth);
        auth = NULL;
    }
    
    return result;
}


- (CFHTTPMessageRef)copyHTTPRequestWithURL:(NSURL *)URL method:(NSString *)method body:(NSString *)body headers:(NSArray *)headers {
    
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)method, (CFURLRef)URL, kCFHTTPVersion1_1);
    
    if ([body length]) {
        CFHTTPMessageSetBody(message, (CFDataRef)[body dataUsingEncoding:NSUTF8StringEncoding]);
    }
    
    for (id header in headers) {
        NSString *name = [header objectForKey:@"name"];
        NSString *value = [header objectForKey:@"value"];
        if ([name length] && [value length]) {
            CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)name, (CFStringRef)value);
        }
    }
    
    NSString *rawMessage = [self rawStringForHTTPMessage:message];
    [self.command setObject:rawMessage forKey:@"rawRequest"];
    
    return message;
}


- (CFHTTPMessageRef)copyResponseBySendingHTTPRequest:(CFHTTPMessageRef)req followRedirects:(BOOL)followRedirects {
    CFHTTPMessageRef response = NULL;
    NSMutableData *responseBodyData = [NSMutableData data];
    
    CFReadStreamRef stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, req);
    CFBooleanRef autoredirect = followRedirects ? kCFBooleanTrue : kCFBooleanFalse;
    CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPShouldAutoredirect, autoredirect);
	
	/* DO SSL Cert Verification Check - GRM 06 MAR 2009 */
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:HCAcceptUnverifiableSSLTextKey] boolValue]) {
		CFMutableDictionaryRef secDictRef = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
				
		if (secDictRef != nil) { 
			CFDictionarySetValue(secDictRef, kCFStreamSSLValidatesCertificateChain, kCFBooleanFalse);
			CFReadStreamSetProperty(stream, kCFStreamPropertySSLSettings, secDictRef);
			CFRelease(secDictRef);
		}
	}
	
    CFReadStreamOpen(stream);    
    
    BOOL done = NO;
    while (!done) {
        UInt8 buf[BUFSIZE];
        CFIndex numBytesRead = CFReadStreamRead(stream, buf, BUFSIZE);
        if (numBytesRead < 0) {
            CFStreamError error = CFReadStreamGetError(stream);
            NSString *msg = [NSString stringWithFormat:@"Network Error. Domain: %d, Code: %d", error.domain, error.error];
            NSLog(@"%@", msg);
            [self failure:msg];
            responseBodyData = nil;
            done = YES;
        } else if (numBytesRead == 0) {
            done = YES;
        } else {
            [responseBodyData appendBytes:buf length:numBytesRead];
        }
    }
    
    CFReadStreamClose(stream);
    NSInteger streamStatus = CFReadStreamGetStatus(stream);
    
    if (kCFStreamStatusError != streamStatus) {
        response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
        CFHTTPMessageSetBody(response, (CFDataRef)responseBodyData);
    }
    
    if (stream) {
        CFRelease(stream);
        stream = NULL;
    }
    
    return response;
}


- (NSString *)rawStringForHTTPMessage:(CFHTTPMessageRef)message {
    
    // ok so this is weird. we're using the declared content-type string encoding on the entire raw messaage. 
    // dunno if that makes sense
    NSStringEncoding encoding = [self stringEncodingForBodyOfHTTPMessage:message];
    NSData *data = (NSData *)CFHTTPMessageCopySerializedMessage(message);
    NSString *result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    
    // if the result is nil, give it one last try with utf8 or preferrably latin1. 
    // ive seen this work for servers that lie (sideways glance at reddit.com)
    if (!result) {
        if (NSISOLatin1StringEncoding == encoding) {
            encoding = NSUTF8StringEncoding;
        } else {
            encoding = NSISOLatin1StringEncoding;
        }
        result = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    }
    [data release];
    return result;
}


- (NSStringEncoding)stringEncodingForBodyOfHTTPMessage:(CFHTTPMessageRef)message {
    
    // use latin1 as the default. why not.
    NSStringEncoding encoding = NSISOLatin1StringEncoding;
    
    // get the content-type header field value
    NSString *contentType = [(id)CFHTTPMessageCopyHeaderFieldValue(message, (CFStringRef)@"Content-Type") autorelease];
    if (contentType) {
        
        // "text/html; charset=utf-8" is common, so just get the good stuff
        NSRange r = [contentType rangeOfString:@"charset="];
        if (NSNotFound == r.location) {
            r = [contentType rangeOfString:@"="];
        }
        if (NSNotFound != r.location) {
            contentType = [contentType substringFromIndex:r.location + r.length];
        }
        
        // trim whitespace
        contentType = [contentType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // convert to an NSStringEncoding
        CFStringEncoding cfStrEnc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)contentType);
        if (kCFStringEncodingInvalidId != cfStrEnc) {
            encoding = CFStringConvertEncodingToNSStringEncoding(cfStrEnc);
        }
    }
    
    return encoding;
}


- (void)success:(NSString *)rawResponse {
    [self performSelectorOnMainThread:@selector(doSuccess:) withObject:rawResponse waitUntilDone:NO];
}


- (void)doSuccess:(NSString *)rawResponse {
    [delegate HTTPService:self didRecieveResponse:rawResponse forRequest:command];
}


- (void)failure:(NSString *)msg {
    [self performSelectorOnMainThread:@selector(doFailure:) withObject:msg waitUntilDone:NO];
}


- (void)doFailure:(NSString *)msg {
    [delegate HTTPService:self request:command didFail:msg];
}

@synthesize delegate;
@synthesize command;
@synthesize authUsername;
@synthesize authPassword;
@end
