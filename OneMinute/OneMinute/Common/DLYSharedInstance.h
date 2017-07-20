//
//  DLYSharedInstance.h
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#define SINGLETON(className) \
\
    static className* sharedInstance = nil; \
+ (instancetype) sharedInstance \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once \
    ( \
        &onceToken, \
        ^ \
        { \
            sharedInstance = [[self alloc] init]; \
            if([sharedInstance respondsToSelector:@selector(instanceInit)]) \
            { \
                [sharedInstance instanceInit]; \
            } \
        } \
    ); \
    \
    return sharedInstance; \
}

@protocol DLYSharedInstance <NSObject>

+(instancetype) sharedInstance;

@optional
-(void) instanceInit;

@end
