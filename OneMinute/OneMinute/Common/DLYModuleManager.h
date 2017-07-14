//
//  DLYModuleManager.h
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYModule.h"
#import <UIKit/UIKit.h>


@interface DLYModuleManager : NSObject <UIApplicationDelegate>

@property (nonatomic, copy) NSString* applicationIdentifier;


#pragma mark - Module APIs
-(DLYModule*) moduleById:(NSString*) moduleId;
-(DLYModule*) moduleByClass:(Class) moduleClass;
-(void) registerModule:(DLYModule*) module;
-(void) unregisterModule:(DLYModule*) module;
-(void) initModules;
-(void) startModules;
-(void) pauseModules;
-(void) resumeModules;
-(void) stopModules;
-(void) releaseModules;
-(NSArray*) modules;

@end
