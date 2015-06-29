//
//  ExceptionHandler.m
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

#import "UncaughtExceptionHandler.h"


@implementation UncaughtExceptionHandler

void exceptionHandler(NSException *exception) {
    SEL captureException = NSSelectorFromString(@"captureUncaughtException:");
    if ([ravenClient respondsToSelector:captureException]) {
        ((void (*)(id, SEL, NSException*))[ravenClient methodForSelector:captureException])(ravenClient, captureException, exception);
    }
}

NSUncaughtExceptionHandler *exceptionHandlerPtr = &exceptionHandler;

+ (void)registerHandler: (id)raven {
    ravenClient = raven;
}

@end
