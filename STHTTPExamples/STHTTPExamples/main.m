//
//  main.m
//  STHTTPExamples
//
//  Created by Ivan Genchev on 20/01/2014.
//  Copyright (c) 2014 Ivan Genchev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STConnectionManager.h"


int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        STHTTPConnection *getConnection = [STHTTPConnection connectionWithURLString:@"http://localhost:8080/test" httpMethod:@"GET" handler:^(STHTTPConnection *connection) {
            NSString *dataString = [[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding];
            NSLog(@"response: %@\nerror: %@", dataString, connection.error);
        }];
        [getConnection start];
        
        STHTTPConnection *postConnection = [STHTTPConnection connectionWithURLString:@"http://localhost:8080/test" httpMethod:@"POST" handler:^(STHTTPConnection *connection) {
            NSString *dataString = [[NSString alloc] initWithData:connection.data encoding:NSUTF8StringEncoding];
            NSLog(@"response: %@\nerror: %@", dataString, connection.error);
        }];
        [postConnection start];
        
        [runLoop run];
    }
    return 0;
}

