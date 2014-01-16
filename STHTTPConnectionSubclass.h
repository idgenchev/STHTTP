/* -*- mode: objc -*- */
// NOTE: Include only in subclasses of STHTTPConnection (simulate protected methods).
#import "STHTTPConnection.h"

@interface STHTTPConnection ()

// NOTE: never call super!
- (void)didFinishLoading;

@end
