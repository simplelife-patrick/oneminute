//
//  DLYModule.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYModule.h"
#import <UIKit/UIKit.h>


static float const kModuleWeightFactorDefault = 0.1;


@interface DLYModule()
{
    NSDictionary* _initInfo;
}

@property (nonatomic) DLYModuleStatus moduleStatus;

@end


@implementation DLYModule

#pragma mark - Overrided APIs

- (id)init
{
    self = [super init];
    if (self) 
    {

    }
    
    return self;
}

- (void)dealloc
{
    [self releaseModule];
}

#pragma mark - Public APIs

-(void) initModule
{
    _moduleWeightFactor = kModuleWeightFactorDefault;
    _moduleStatus = DLYModuleStatus_New;
    
    NSString* moduleName = NSStringFromClass([self class]);
    
    [self setModuleIdentity:moduleName];
    [self.serviceThread setName:moduleName];
    
    NSLog(@"%@ - initModule", self.moduleIdentity);
    
    [self registerNotifications];
    
    _moduleStatus = DLYModuleStatus_Initialized;
}

-(void) releaseModule
{
    NSLog(@"%@ - releaseModule", self.moduleIdentity);
    
    [self unregisterNotifications];
    
    _moduleStatus = DLYModuleStatus_Released;
}

-(void) startService
{
    NSLog(@"%@ - startService", self.moduleIdentity);
    
    if (self.individualThread)
    {
        self.serviceThread = [[NSThread alloc] initWithTarget:self selector:@selector(processService) object:nil];
        
        [self.serviceThread start];
    }
    else
    {
        [self processService];
    }
}

-(void) pauseService
{
    NSLog(@"%@ - pauseService", self.moduleIdentity);
}

-(void) resumeService
{
    NSLog(@"%@ - resumeService", self.moduleIdentity);
}

-(void) processService
{
    NSLog(@"%@ - processService", self.moduleIdentity);
    
    if (0 < DLYModule_ModuleDelay)
    {
        [NSThread sleepForTimeInterval:DLYModule_ModuleDelay];
    }
    
    _moduleStatus = DLYModuleStatus_InService;
}

-(void) stopService
{
    NSLog(@"%@ - stopService", self.moduleIdentity);
}

-(void) registerNotifications
{
    NSLog(@"%@ - registerNotifications", self.moduleIdentity);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

-(void) unregisterNotifications
{
    NSLog(@"%@ - unregisterNotifications", self.moduleIdentity);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

-(void) applicationWillResignActive:(NSNotification*) notification
{
    NSLog(@"%@ - applicationWillResignActive", self.moduleIdentity);
}

-(void) applicationDidEnterBackground:(NSNotification*) notification
{
    NSLog(@"%@ - applicationDidEnterBackground", self.moduleIdentity);
}

-(void) applicationWillEnterForeground:(NSNotification*) notification
{
    NSLog(@"%@ - applicationWillEnterForeground", self.moduleIdentity);
}

-(void) applicationDidBecomeActive:(NSNotification*) notification
{
    NSLog(@"%@ - applicationDidBecomeActive", self.moduleIdentity);
}

-(void) applicationWillTerminate:(NSNotification*) notification
{
    NSLog(@"%@ - applicationWillTerminate", self.moduleIdentity);
}

@end
