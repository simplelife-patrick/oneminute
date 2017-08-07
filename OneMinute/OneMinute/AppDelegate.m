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

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
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
        DLYLog(@"📱📱📱The Application Did First Finish Launch !");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        
        NSString *documentPath = [homeDir objectAtIndex:0];
        NSString *dataPath = [documentPath stringByAppendingPathComponent:kDataFolder];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
            
            if (![fileManager fileExistsAtPath:draftPath]) {
                [fileManager createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *templatePath = [dataPath stringByAppendingPathComponent:kTemplateFolder];
            
            if (![fileManager fileExistsAtPath:templatePath]) {
                [fileManager createDirectoryAtPath:templatePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *samplesPath = [dataPath stringByAppendingPathComponent:kSampleFolder];
            
            if (![fileManager fileExistsAtPath:samplesPath]) {
                [fileManager createDirectoryAtPath:samplesPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *productsPath = [dataPath stringByAppendingPathComponent:kProductFolder];
            
            if (![fileManager fileExistsAtPath:productsPath]) {
                [fileManager createDirectoryAtPath:productsPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *resourcePath = [dataPath stringByAppendingPathComponent:kResourceFolder];
            
            if (![fileManager fileExistsAtPath:resourcePath]) {
                [fileManager createDirectoryAtPath:resourcePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        NSArray *dataFolderArray = [fileManager contentsOfDirectoryAtPath:dataPath error:nil];
        DLYLog(@"当前Data目录下有 %lu 个文件夹\n %@",dataFolderArray.count,dataFolderArray);
        
        DLYLaunchPlayerViewController *vc = [[DLYLaunchPlayerViewController alloc] init];
        self.window.rootViewController = vc;
        [self.window makeKeyAndVisible];
    }else{
        DLYLog(@"📱📱📱The Application isn't First Finish Launch !");
        //不是首次启动
        DLYRecordViewController *vc = [[DLYRecordViewController alloc] init];
        DLYBaseNavigationController *nvc = [[DLYBaseNavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nvc;
        [self.window makeKeyAndVisible];
    }
    
    [NSThread sleepForTimeInterval:3]; // 设置启动页面停留时间
    ///申请麦克风权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
    }];
    ///申请拍照权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
    }];
    ///申请相册权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    }];
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    DLYLog(@"📱📱📱The Application Will Resign Active !");

}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    DLYLog(@"📱📱📱The Application Did Enter Background !");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    DLYLog(@"📱📱📱The Application Will Enter Foreground !");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    DLYLog(@"📱📱📱The Application Did Become Active !");
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DLYLog(@"📱📱📱The Application Will Terminate !");
}


@end
