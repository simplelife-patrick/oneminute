//
//  DLYModule.h
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYAsyncQueue.h"


static NSTimeInterval const DLYModule_ModuleDelay = 0.0f;


typedef NS_ENUM(NSUInteger, DLYModuleStatus)
{
    DLYModuleStatus_New = 0,
    DLYModuleStatus_Initialized,
    DLYModuleStatus_InService,
    DLYModuleStatus_Paused,
    DLYModuleStatus_Stopped,
    DLYModuleStatus_Released
};


@interface DLYModule : NSObject

@property (nonatomic) BOOL individualThread;
@property (nonatomic, copy) NSString *moduleIdentity;
@property (nonatomic, strong) NSThread *serviceThread;
@property (nonatomic) float moduleWeightFactor;
@property (nonatomic, readonly) DLYModuleStatus moduleStatus;

-(void) initModule;
-(void) startService;
-(void) processService;
-(void) pauseService;
-(void) resumeService;
-(void) stopService;
-(void) releaseModule;

-(void) registerNotifications;
-(void) unregisterNotifications;

-(void) applicationWillResignActive:(NSNotification*) notification;
-(void) applicationDidEnterBackground:(NSNotification*) notification;
-(void) applicationWillEnterForeground:(NSNotification*) notification;
-(void) applicationDidBecomeActive:(NSNotification*) notification;
-(void) applicationWillTerminate:(NSNotification*) notification;

@end
