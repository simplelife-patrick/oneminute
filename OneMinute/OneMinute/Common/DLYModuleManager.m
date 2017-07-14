//
//  DLYModuleManager.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYModuleManager.h"


@interface DLYModuleManager()
{
    NSMutableArray* _modules;
}

@end


@implementation DLYModuleManager

-(id) init
{
    self = [super init];
    if (self)
    {
        _modules = [NSMutableArray array];
        _applicationIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        
        [self _registerDefaultsModules];
    }
    return self;
}

#pragma mark - Public APIs

-(DLYModule*) moduleById:(NSString*) moduleId
{
    __block DLYModule* module = nil;
    
    [_modules enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DLYModule* m = (DLYModule*)obj;
        if ([m.moduleIdentity isEqualToString:moduleId])
        {
            module = m;
            *stop = YES;
        }
    }];
    
    return module;
}

-(DLYModule*) moduleByClass:(Class) moduleClass
{
    return [self moduleById:NSStringFromClass(moduleClass)];
}

-(void) registerModule:(DLYModule*) module
{
    if (nil != module)
    {
        [_modules addObject:module];
    }
}

-(void) unregisterModule:(DLYModule*) module
{
    if (nil != module)
    {
        for (DLYModule* m in _modules)
        {
            if (module == m)
            {
                [_modules removeObject:m];
                break;
            }
        }
    }
}

-(void) initModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m initModule];
        }
    }
}

-(void) startModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m startService];
        }
    }
}

-(void) pauseModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m pauseService];
        }
    }
}

-(void) resumeModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m resumeService];
        }
    }
}

-(void) stopModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m stopService];
        }
    }
}

-(void) releaseModules
{
    for (DLYModule* m in _modules)
    {
        if (nil != m)
        {
            [m releaseModule];
        }
    }
}

-(NSArray*) modules
{
    return _modules;
}

#pragma mark - Private APIs

-(void) _registerDefaultsModules
{
    
}

@end
