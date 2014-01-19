#import "STConnectionManager.h"

static STConnectionManager* sharedSTConnectionManager = nil;

@interface STConnectionManager ()

@property (nonatomic, assign, readwrite) NSUInteger runningConnectionsCount;

- (void)incrementConnectionCount;
- (void)decrementConnectionCount;

@end

@implementation STConnectionManager

#pragma mark -
#pragma mark Singleton Pattern
#pragma mark -

+ (STConnectionManager*)sharedSTConnectionManager {
    @synchronized(self) {
        if (sharedSTConnectionManager == nil) {
            sharedSTConnectionManager = [[self alloc] init];
        }
    }
    return sharedSTConnectionManager;
}

- (id)init {
    if (self = [super init]) {
        self.runningConnectionsCount = 0;
    }
    return self;
}

+ (id)allocWithZone:(NSZone*)zone {
    @synchronized(self) {
        if (sharedSTConnectionManager == nil) {
            // assignment and return on first allocation
            sharedSTConnectionManager = [super allocWithZone:zone];
            return sharedSTConnectionManager;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)incrementConnectionCount {
    BOOL movingToInUse;
    movingToInUse = (self.runningConnectionsCount == 0);
    if (movingToInUse) {
        [self willChangeValueForKey:@"networkInUse"];
    }
    self.runningConnectionsCount += 1;
    if (movingToInUse) {
        [self didChangeValueForKey:@"networkInUse"];
    }
}

- (void)decrementConnectionCount {
    BOOL movingToNotInUse;
    movingToNotInUse = (self.runningConnectionsCount == 1);
    if (movingToNotInUse) {
        [self willChangeValueForKey:@"networkInUse"];
    }
    self.runningConnectionsCount -= 1;
    if (movingToNotInUse) {
        [self didChangeValueForKey:@"networkInUse"];
    }
}

- (void)startConnection:(STHTTPConnection*)connection withHandler:(STConnectionHandler)handler {
    connection.completionHandler = ^(STHTTPConnection *connection) {
        @synchronized (self) {
            [self performSelectorOnMainThread:@selector(decrementConnectionCount) withObject:nil waitUntilDone:NO];
            if (!connection.isCancelled) handler(connection);
        }
    };
    
    @synchronized (self) {
        [self performSelectorOnMainThread:@selector(incrementConnectionCount) withObject:nil waitUntilDone:NO];
        [connection start];
    }
}

- (void)setNetworkInUse:(BOOL)networkInUse {
    @synchronized (self) { _networkInUse = networkInUse; }
}

@end
