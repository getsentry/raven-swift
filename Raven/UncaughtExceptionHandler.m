//
//  ExceptionHandler.m
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

#import "UncaughtExceptionHandler.h"

//NOTE: Change this to YourProductModuleName-Swift.h
//Ref: https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html
#import "Raven/Raven-Swift.h"

@implementation UncaughtExceptionHandler

void exceptionHandler(NSException *exception) {
    [[RavenClient sharedClient] captureException:exception];
}

NSUncaughtExceptionHandler *exceptionHandlerPtr = &exceptionHandler;

@end
