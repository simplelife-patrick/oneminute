//
//  AppDelegate.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "AppDelegate.h"
#import "DLYLaunchPlayerViewController.h"
#import "DLYRecordViewController.h"
#import "DLYBaseNavigationController.h"
#import "DLYAnimationViewController.h"


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[[Crashlytics class]]];

    //友盟统计
    UMConfigInstance.appKey = @"596c2805bbea83404400035b";
    UMConfigInstance.channelId = @"App Store";
//    [MobClick setLogEnabled:YES];
    [MobClick startWithConfigure:UMConfigInstance];//配置以上参数后调用此方法初始化SDK！
    [MobClick setAppVersion:XcodeAppVersion];//这里是当前的版本
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]){
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
        DLYLog(@"The Application Did First Finish Launch !");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
            if (![fileManager fileExistsAtPath:draftPath]) {
                [fileManager createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *tempPath = [dataPath stringByAppendingPathComponent:kTempFolder];
            if (![fileManager fileExistsAtPath:tempPath]) {
                [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *productsPath = [dataPath stringByAppendingPathComponent:kProductFolder];
            if (![fileManager fileExistsAtPath:productsPath]) {
                [fileManager createDirectoryAtPath:productsPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        NSArray *dataFolderArray = [fileManager contentsOfDirectoryAtPath:dataPath error:nil];
        DLYLog(@"当前Document/Data目录下有 %lu 个文件夹\n %@",dataFolderArray.count,dataFolderArray);

    }else{
        DLYLog(@"The Application isn't First Finish Launch !");
    }
    
    DLYAnimationViewController *vc = [[DLYAnimationViewController alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    //常亮
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    DLYLog(@"The Application Will Resign Active !");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DLYLog(@"The Application Did Enter Background !");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DLYLog(@"The Application Will Enter Foreground !");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DLYLog(@"The Application Did Become Active !");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DLYLog(@"The Application Will Terminate !");
}

@end
