/* -*- mode: objc -*- */

typedef void (^STHTTPConnectionHandler)(id);

@interface STHTTPConnection : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
{
@protected
    NSError *_error;
    BOOL _loadingData;
}

@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic) NSURLCacheStoragePolicy cachePolicy;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSDictionary *parameters;

@property (nonatomic, weak) id receiver;
@property (nonatomic) SEL action;
@property (nonatomic, copy) STHTTPConnectionHandler completionHandler;

@property (atomic, readonly, getter = isLoadingData) BOOL loadingData;
@property (nonatomic) NSHTTPURLResponse *httpResponse;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSError *error;

+ (id)connectionWithURLRequest:(NSURLRequest*)request
                   receiver:(id)receiver
                     action:(SEL)action;
+ (id)connectionWithURLString:(NSString*)urlString
                httpMethod:(NSString*)method
                  receiver:(id)receiver
                    action:(SEL)action;

+ (id)connectionWithURLRequest:(NSURLRequest*)request
                    handler:(STHTTPConnectionHandler)handler;
+ (id)connectionWithURLString:(NSString*)urlString
                httpMethod:(NSString*)method
                   handler:(STHTTPConnectionHandler)handler;

- (id)initWithURLRequest:(NSURLRequest*)request
                receiver:(id)receiver
                  action:(SEL)action;
- (id)initWithURLString:(NSString*)urlString
             httpMethod:(NSString*)method
               receiver:(id)receiver
                 action:(SEL)action;

- (id)initWithURLRequest:(NSURLRequest*)request
                 handler:(STHTTPConnectionHandler)handler;
- (id)initWithURLString:(NSString*)urlString
             httpMethod:(NSString*)method
                handler:(STHTTPConnectionHandler)handler;

- (void)start;
- (void)cancel;

@end
