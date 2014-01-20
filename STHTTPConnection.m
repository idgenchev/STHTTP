#import "STHTTPConnection.h"
#import "STHTTPConnectionSubclass.h"

BOOL isContainer(Class class) {
    BOOL container = NO;
    if ([class isKindOfClass:[NSDictionary class]]) {
        
    } else if ([class isKindOfClass:[NSArray class]]) {
        
    } else if ([class isKindOfClass:[NSSet class]]) {
        
    }
    return container;
}

@interface STHTTPConnection ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;

- (NSString*)requestBodyFromDictionary:(NSDictionary*)parameters;
- (void)setMultipartRequestBody:(NSMutableURLRequest*)request fromDictionary:(NSDictionary*)parameters;

@end

@implementation STHTTPConnection

@synthesize error = _error;
@synthesize loadingData = _loadingData;

+ (id)connectionWithURLRequest:(NSURLRequest*)request parameters:(NSDictionary*)parameters {
    id connection = [[[self class] alloc] initWithURLRequest:request handler:nil];
    ((STHTTPConnection*)connection).parameters = parameters;
    return connection;
}

+ (id)connectionWithURLString:(NSString*)urlString httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters {
    id connection = [[[self class] alloc] initWithURLString:urlString httpMethod:httpMethod handler:nil];
    ((STHTTPConnection*)connection).parameters = parameters;
    return connection;
}

+ (id)connectionWithURLRequest:(NSURLRequest*)request receiver:(id)receiver action:(SEL)action {
    return [[[self class] alloc] initWithURLRequest:request receiver:receiver action:action];
}

+ (id)connectionWithURLString:(NSString*)urlString httpMethod:(NSString*)method receiver:(id)receiver action:(SEL)action {
    return [[[self class] alloc] initWithURLString:urlString httpMethod:method receiver:receiver action:action];
}

+ (id)connectionWithURLRequest:(NSURLRequest*)request handler:(STHTTPConnectionHandler)handler {
    return [[[self class] alloc] initWithURLRequest:request handler:handler];
}

+ (id)connectionWithURLString:(NSString*)urlString httpMethod:(NSString*)method handler:(STHTTPConnectionHandler)handler {
    return [[[self class] alloc] initWithURLString:urlString httpMethod:method handler:handler];
}

- (id)initWithURLRequest:(NSURLRequest*)request receiver:(id)receiver action:(SEL)action {
    if (self = [super init]) {
        self.request = request;
        self.receiver = receiver;
        self.action = action;
        [self setDefaults];
    }
    return self;
}

- (id)initWithURLString:(NSString*)urlString httpMethod:(NSString*)method receiver:(id)receiver action:(SEL)action {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:method];
        self.request = request;
        self.receiver = receiver;
        self.action = action;
        [self setDefaults];
    }
    return self;
}

- (id)initWithURLRequest:(NSURLRequest*)request handler:(STHTTPConnectionHandler)handler {
    if (self = [super init]) {
        self.request = request;
        self.completionHandler = handler;
        [self setDefaults];
    }
    return self;
}

- (id)initWithURLString:(NSString*)urlString httpMethod:(NSString*)method handler:(STHTTPConnectionHandler)handler {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:method];
        self.request = request;
        self.completionHandler = handler;
        [self setDefaults];
    }
    return self;
}

- (void)setDefaults {
    self.cachePolicy = NSURLCacheStorageNotAllowed;
    self.timeoutInterval = 30.0;
}

- (void)start {
    self.loadingData = YES;
    
    self.mutableData = [NSMutableData data];
    
    NSMutableURLRequest *mutableRequest;
    
    if ([self.httpHeaderFields[@"Content-Type"] isEqualToString:@"multipart/form-data"]) {
        mutableRequest = [NSMutableURLRequest requestWithURL:self.request.URL cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
        [self setMultipartRequestBody:mutableRequest fromDictionary:self.parameters];
        mutableRequest.HTTPMethod = self.request.HTTPMethod ? self.request.HTTPMethod : @"POST";
    } else {
        if (self.request.HTTPMethod &&
            ([self.request.HTTPMethod isEqualToString:@"PUT"] || [self.request.HTTPMethod isEqualToString:@"POST"])) {
            mutableRequest = [NSMutableURLRequest requestWithURL:self.request.URL cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
            [mutableRequest setHTTPBody:[[self requestBodyFromDictionary:self.parameters] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            NSString *urlString = [NSString stringWithFormat:@"%@?%@", [self.request.URL absoluteString], [self requestBodyFromDictionary:self.parameters]];
            mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
        }
        [mutableRequest setHTTPMethod:self.request.HTTPMethod ? self.request.HTTPMethod : @"GET"];
    }
    
    if (self.httpHeaderFields.count > 0) {
        [self.httpHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *headerField, NSString *value, BOOL *stop) {
            [mutableRequest setValue:value forHTTPHeaderField:headerField];
        }];
    }
    
    self.request = mutableRequest;
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
}

- (void)cancel {
    self.cancelled = YES;
    [self.connection cancel];
	self.connection = nil;
	self.receiver = nil;
    self.completionHandler = nil;
    self.loadingData = NO;
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest setURL:[request URL]];
        return mutableRequest;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    self.httpResponse = (NSHTTPURLResponse*)response;
    if (self.httpResponse.statusCode >= 400) {
        // TODO: add descriptions in the userInfo for the status codes (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
        NSError *error = [NSError errorWithDomain:@"HTTP" code:self.httpResponse.statusCode userInfo:nil];
        self.error = error;
        [connection cancel];
        [self didFinishLoading];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.mutableData appendData:data];
}

// TODO:
// - (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request;
// - (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [self didFinishLoading];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    [self didFinishLoading];
}

// TODO:
// - (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
// - (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (void)didFinishLoading {
    self.loadingData = NO;
    if (self.completionHandler) { self.completionHandler(self); }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.receiver) { [self.receiver performSelector:self.action withObject:self]; }
#pragma clang diagnostic pop
}

- (NSString*)requestBodyFromDictionary:(NSDictionary*)parameters {
    NSMutableString *body = [NSMutableString string];
	
    if (parameters) {
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                [(NSArray*)obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [body appendFormat:@"%@=%@&", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }];
            } else if ([obj isKindOfClass:[NSSet class]]) {
                [(NSSet*)obj enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    [body appendFormat:@"%@=%@&", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }];
            } else if ([obj isKindOfClass:[NSData class]]) {
                NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([obj length] * 2)];
                const unsigned char *dataBuffer = [obj bytes];
				
                for (int i = 0; i < [obj length]; ++i) {
                    [stringBuffer appendFormat:@"%02lX", (intptr_t)dataBuffer[i]];
                }
                [body appendFormat:@"%@=%@&", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], stringBuffer];
            } else {
                if ([obj isKindOfClass:[NSString class]]) {
                    [body appendFormat:@"%@=%@&", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[obj copy] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }
            }
        }];
        
        // delete the last &
        if ((body.length) && ([body characterAtIndex:body.length-1] == '&')) [body deleteCharactersInRange:NSMakeRange([body length] - 1, 1)];
    }
	
    return body;
}

- (void)setMultipartRequestBody:(NSMutableURLRequest*)request fromDictionary:(NSDictionary*)parameters {
    NSString *boundary = @"0xB0un9ArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"1.0" forHTTPHeaderField:@"MIME-Version"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    NSMutableData *body = [NSMutableData data];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        if ([obj isKindOfClass:[NSString class]]) {
            [body appendData:[[NSString stringWithFormat:@"Content-Type: text/plain\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@\r\n", obj] dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", obj[@"Content-Type"]] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:obj[@"data"]];
        }
    }];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
}

#pragma mark -
#pragma mark properties

- (NSError*)error { return _error; }
- (void)setError:(NSError *)error { _error = error; }
- (BOOL)isLoadingData { return _loadingData; }
- (void)setLoadingData:(BOOL)loadingData {
    @synchronized (self) { _loadingData = loadingData; }
}

- (NSData*)data { return [NSData dataWithData:self.mutableData]; }

- (void)setCancelled:(BOOL)cancelled { _cancelled = cancelled; }

@end
