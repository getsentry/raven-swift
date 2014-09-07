//
//  ExceptionHandler.h
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//  Copyright (c) 2014 OKB. All rights reserved.
//

#import <Foundation/Foundation.h>

volatile void exceptionHandler(NSException *exception);
extern NSUncaughtExceptionHandler *exceptionHandlerPtr;

@interface UncaughtExceptionHandler : NSObject 

+ (void) raise: (NSString *) messsage;

@end
