//
//  AppDelegate.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]){
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunch"];
        NSLog(@"首次启动");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        
        NSString *documentPath = [homeDir objectAtIndex:0];
        NSString *dataPath = [documentPath stringByAppendingPathComponent:DataFolder];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSString *draftPath = [dataPath stringByAppendingPathComponent:DraftFolder];
            
            if (![fileManager fileExistsAtPath:draftPath]) {
                [fileManager createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *templatePath = [dataPath stringByAppendingPathComponent:TemplateFolder];
            
            if (![fileManager fileExistsAtPath:templatePath]) {
                [fileManager createDirectoryAtPath:templatePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *samplesPath = [dataPath stringByAppendingPathComponent:SampleFolder];
            
            if (![fileManager fileExistsAtPath:samplesPath]) {
                [fileManager createDirectoryAtPath:samplesPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *productsPath = [dataPath stringByAppendingPathComponent:ProductFolder];
            
            if (![fileManager fileExistsAtPath:productsPath]) {
                [fileManager createDirectoryAtPath:productsPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *resourcePath = [dataPath stringByAppendingPathComponent:ResourceFolder];
            
            if (![fileManager fileExistsAtPath:resourcePath]) {
                [fileManager createDirectoryAtPath:resourcePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        NSArray *dataFolderArray = [fileManager contentsOfDirectoryAtPath:dataPath error:nil];
        NSLog(@"当前Data目录下有 %lu 个文件夹\n %@",dataFolderArray.count,dataFolderArray);
        
    }else{
        NSLog(@"不是第一次启动了");
    }
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
