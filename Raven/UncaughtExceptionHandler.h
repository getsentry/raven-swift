//
//  ExceptionHandler.h
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

#import <Foundation/Foundation.h>

void exceptionHandler(NSException *exception);
extern NSUncaughtExceptionHandler *exceptionHandlerPtr;

@interface UncaughtExceptionHandler : NSObject 

@end
