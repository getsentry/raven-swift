//
//  ExceptionHandler.m
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//  Copyright (c) 2014 OKB. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
#import "Raven-Swift.h"

@implementation UncaughtExceptionHandler

volatile void exceptionHandler(NSException *exception) {
    [[RavenClient sharedClient] captureException:exception sendNow:NO];
}

NSUncaughtExceptionHandler *exceptionHandlerPtr = &exceptionHandler;

+ (void) raise: (NSString *)message{
    [NSException raise:@"TestException" format:@"%@", message];
}

@end
