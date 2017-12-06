
//
//  DLYContextManager.m
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYContextManager.h"

@implementation DLYContextManager

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    static DLYContextManager *instance = nil;
    dispatch_once(&predicate, ^{instance = [[self alloc] init];});
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null]};
        _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:options];
    }
    return self;
}

@end
