//
//  ExceptionHandler.m
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

#import "UncaughtExceptionHandler.h"
#import "Raven-Swift.h"

@implementation UncaughtExceptionHandler

void exceptionHandler(NSException *exception) {
    [[RavenClient sharedClient] captureException:exception sendNow:NO];
}

NSUncaughtExceptionHandler *exceptionHandlerPtr = &exceptionHandler;

+ (void) raise: (NSString *)message{
    [NSException raise:@"TestException" format:@"%@", message];
}

@end
