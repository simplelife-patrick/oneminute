//
//  DLYLogModule.h
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYModule.h"
#import "DLYSharedInstance.h"


#define DLYLogService [DLYLogModule sharedInstance]
#define DLYLog(fmt, ...) [DLYLogService loggerFormat:(fmt), ##__VA_ARGS__]

#define DLYLogInfo(fmt, ...)    DLYLog(@"%@ " fmt, @"[INFO] ",  ##__VA_ARGS__)
#define DLYLogDebug(fmt, ...)   DLYLog(@"%@ " fmt, @"[DEBUG] ", ##__VA_ARGS__)
#define DLYLogError(fmt, ...)   DLYLog(@"%@ " fmt, @"[ERROR] ", ##__VA_ARGS__)


@interface DLYLogModule : DLYModule <DLYSharedInstance>

- (void)loggerFormat:(NSString *)format, ...;

@end
