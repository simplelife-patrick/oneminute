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
#import <UMSocialCore/UMSocialCore.h>
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

    if (NEW_FUNCTION) {
        //友盟分享
        //[[UMSocialManager defaultManager] openLog:YES];
        /* 设置友盟appkey */
        [[UMSocialManager defaultManager] setUmSocialAppkey:@"596c2805bbea83404400035b"];
        
        [self configUSharePlatforms];
        [self confitUShareSettings];
    }

    [MobClick startWithConfigure:UMConfigInstance];//配置以上参数后调用此方法初始化SDK！
    [MobClick setAppVersion:XcodeAppVersion];//这里是当前的版本
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSDictionary*infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *localVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"currentVersion"]||![[[NSUserDefaults standardUserDefaults] valueForKey:@"currentVersion"] isEqualToString:localVersion]) {
        [[NSUserDefaults standardUserDefaults] setValue:localVersion forKey:@"currentVersion"];
        DLYLog(@"The Application Did First Finish Launch !");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
            if (![fileManager fileExistsAtPath:draftPath]) {
                [fileManager createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *virtualPath = [dataPath stringByAppendingPathComponent:kVirtualFolder];
            if (![fileManager fileExistsAtPath:virtualPath]) {
                [fileManager createDirectoryAtPath:virtualPath withIntermediateDirectories:YES attributes:nil error:nil];
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
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    return result;
}
- (void)confitUShareSettings
{
    /*
     * 打开图片水印
     */
    //[UMSocialGlobal shareInstance].isUsingWaterMark = YES;
    
    /*
     * 关闭强制验证https，可允许http图片分享，但需要在info.plist设置安全域名
     <key>NSAppTransportSecurity</key>
     <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
     </dict>
     */
    //[UMSocialGlobal shareInstance].isUsingHttpsWhenShareContent = NO;
}

- (void)configUSharePlatforms
{
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:@"wxdc1e388c3822c80b" appSecret:@"3baf1193c85774b3fd9d18447d76cab0" redirectURL:nil];
    //移除微信收藏
    [[UMSocialManager defaultManager] removePlatformProviderWithPlatformTypes:@[@(UMSocialPlatformType_WechatFavorite)]];

    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:@"4263810860"  appSecret:@"5bdaadedb9336fdcaa9adad93b2372c2" redirectURL:@"http://dlytv.com"];
    
}
@end
