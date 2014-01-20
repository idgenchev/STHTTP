#import "STJSONConnection.h"
#import "STHTTPConnectionSubclass.h"

@implementation STJSONConnection

- (void)didFinishLoading {
    self.loadingData = NO;
    if (!self.error) {
        NSError *error = nil;
        self.json = [NSJSONSerialization JSONObjectWithData:self.data options:NSJSONReadingMutableContainers error:&error];
        self.error = error;
    }
    if (self.completionHandler) { self.completionHandler(self); }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.receiver) { [self.receiver performSelector:self.action withObject:self]; }
#pragma clang diagnostic pop
}

- (void)setError:(NSError*)error { _error = error; }
- (void)setLoadingData:(BOOL)loadingData { _loadingData = loadingData; }

@end
