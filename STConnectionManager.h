/* -*- mode: objc -*- */
#import "STHTTPConnection.h"

typedef void(^STConnectionHandler)(STHTTPConnection *connection);

@interface STConnectionManager : NSObject

@property (atomic, assign, readonly) NSUInteger runningConnectionsCount;
@property (atomic, readonly, getter = isNetworkInUse) BOOL networkInUse;

+ (STConnectionManager*)sharedSTConnectionManager;

- (void)startConnection:(STHTTPConnection*)connection withHandler:(STConnectionHandler)handler;

@end
