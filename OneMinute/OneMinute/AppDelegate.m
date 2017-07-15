//
//  AppDelegate.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "AppDelegate.h"
#import "DLYCatchCrash.h"
#import "DLYLaunchPlayerViewController.h"
#import "DLYRecordViewController.h"
#import "DLYBaseNavigationController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    //保存周期
    fileLogger.rollingFrequency = 60 * 60 * 24 * 7; // 7 day
    //最大的日志文件数量
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    
    
    
    [DDLog addLogger:fileLogger];
    
    //注册消息处理函数的处理方法
    //如此一来，程序崩溃时会自动进入FCatchCrash.m的uncaughtExceptionHandler()方法
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [self judgeIsHaveCrash];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
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
        
        DLYLaunchPlayerViewController *vc = [[DLYLaunchPlayerViewController alloc] init];
        self.window.rootViewController = vc;
        [self.window makeKeyAndVisible];
        
    }else{
        NSLog(@"不是第一次启动了");
        //不是首次启动
        DLYRecordViewController *vc = [[DLYRecordViewController alloc] init];
        DLYBaseNavigationController *nvc = [[DLYBaseNavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nvc;
        [self.window makeKeyAndVisible];
        
    }
    return YES;
}

-(void)judgeIsHaveCrash {
    //若crash文件存在，则写入log并上传，然后删掉crash文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *errorLogPath = [NSString stringWithFormat:@"%@/Documents/error.log", NSHomeDirectory()];
    
    NSString * logsPath = [NSString stringWithFormat:@"%@/Library/Caches/Logs", NSHomeDirectory()];
    
    if ([fileManager fileExistsAtPath:errorLogPath]) {
        //用CocoaLumberJack库的fileLogger.logFileManager自带的方法创建一个新的Log文件，这样才能获取到对应文件夹下排序的Log文件
        DDFileLogger * fileLogger = [DDFileLogger new];
        [fileLogger.logFileManager createNewLogFile];
        //此处必须用firstObject而不能用lastObject，因为是按照日期逆序排列的，即最新的Log文件排在前面
        NSString *newLogFilePath = [fileLogger.logFileManager sortedLogFilePaths].firstObject;
        NSError *error = nil;
        NSString *errorLogContent = [NSString stringWithContentsOfFile:errorLogPath encoding:NSUTF8StringEncoding error:nil];
        BOOL isSuccess = [errorLogContent writeToFile:newLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (!isSuccess) {
            DLog(@"crash文件写入log失败: %@", error.userInfo);
        } else {
            DLog(@"crash文件写入log成功");
            DDLogInfo(@"cdbchdh");
            NSError *error = nil;
            BOOL isSuccess = [fileManager removeItemAtPath:errorLogPath error:&error];
            if (!isSuccess) {
                DLog(@"删除本地的crash文件失败: %@", error.userInfo);
            }
        }
        
        //上传最近的3个log文件，
        //至少要3个，因为最后一个是crash的记录信息，另外2个是防止其中后一个文件只写了几行代码而不够分析
        NSArray *logFilePaths = [fileLogger.logFileManager sortedLogFilePaths];
        NSUInteger logCounts = logFilePaths.count;
        NSMutableArray * logsArray = [[NSMutableArray alloc]init];
        if (logCounts >= 3) {
            for (NSUInteger i = 0; i < 3; i++) {
                NSString*str=[[NSString alloc] initWithContentsOfFile:logFilePaths[i] encoding:NSUTF8StringEncoding error:nil];
                [logsArray addObject:str];
                
                //                NSString *logFilePath = logFilePaths[i];
                //上传服务器
            }
        } else {
            for (NSUInteger i = 0; i < logCounts; i++) {
                //                NSString *logFilePath = logFilePaths[i];
                NSString*str=[[NSString alloc] initWithContentsOfFile:logFilePaths[i] encoding:NSUTF8StringEncoding error:nil];
                [logsArray addObject:str];
                //上传服务器
            }
        }
        if(logsArray.count > 0)
        {
            //需要上传到后台的日志
            NSString * jsonString = [logsArray JSONString];
        }
        
        
        //上传成功后删除本地存放的log
        BOOL isLogsSuccess = [fileManager removeItemAtPath:logsPath error:&error];
        if (!isLogsSuccess) {
            DLog(@"删除本地的crash文件失败: %@", error.userInfo);
        }
    }
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
