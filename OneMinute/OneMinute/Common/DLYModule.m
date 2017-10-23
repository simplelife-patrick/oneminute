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
    
//    DLYLog(@"%@ - initModule", self.moduleIdentity);
    
    [self registerNotifications];
    
    _moduleStatus = DLYModuleStatus_Initialized;
}

-(void) releaseModule
{
//    DLYLog(@"%@ - releaseModule", self.moduleIdentity);
    
    [self unregisterNotifications];
    
    _moduleStatus = DLYModuleStatus_Released;
}

-(void) startService
{
    DLYLog(@"%@ - startService", self.moduleIdentity);
    
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
    DLYLog(@"%@ - pauseService", self.moduleIdentity);
}

-(void) resumeService
{
    DLYLog(@"%@ - resumeService", self.moduleIdentity);
}

-(void) processService
{
    DLYLog(@"%@ - processService", self.moduleIdentity);
    
    if (0 < DLYModule_ModuleDelay)
    {
        [NSThread sleepForTimeInterval:DLYModule_ModuleDelay];
    }
    
    _moduleStatus = DLYModuleStatus_InService;
}

-(void) stopService
{
    DLYLog(@"%@ - stopService", self.moduleIdentity);
}

-(void) registerNotifications
{
    DLYLog(@"%@ - registerNotifications", self.moduleIdentity);
    
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
//    DLYLog(@"%@ - unregisterNotifications", self.moduleIdentity);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

-(void) applicationWillResignActive:(NSNotification*) notification
{
    DLYLog(@"%@ - applicationWillResignActive", self.moduleIdentity);
}

-(void) applicationDidEnterBackground:(NSNotification*) notification
{
    DLYLog(@"%@ - applicationDidEnterBackground", self.moduleIdentity);
}

-(void) applicationWillEnterForeground:(NSNotification*) notification
{
    DLYLog(@"%@ - applicationWillEnterForeground", self.moduleIdentity);
}

-(void) applicationDidBecomeActive:(NSNotification*) notification
{
    DLYLog(@"%@ - applicationDidBecomeActive", self.moduleIdentity);
}

-(void) applicationWillTerminate:(NSNotification*) notification
{
    DLYLog(@"%@ - applicationWillTerminate", self.moduleIdentity);
}

@end
