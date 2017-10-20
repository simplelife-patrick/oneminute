//
//  DLYUserTrack.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/10/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYUserTrack.h"

@implementation DLYUserTrack

+ (void)recordAndEventKey:(NSString *)eventKey andDescribeStr:(NSString *)describeStr andPartNum:(NSString *)partNum {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:dateTime forKey:@"dateTime"];
   
    if (describeStr != nil) {
        [dict setObject:describeStr forKey:@"describeStr"];
    }
    if (partNum != nil) {
        [dict setObject:partNum forKey:@"partNum"];
    }

    DLYLog(@"方法3Key===%@", eventKey);
    DLYLog(@"方法3Value===%@", dict);

    //调用友盟的方法
    [MobClick event:eventKey attributes:dict];

}

+ (void)recordAndEventKey:(NSString *)eventKey andDescribeStr:(NSString *)describeStr {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:dateTime forKey:@"dateTime"];
    
    if (describeStr != nil) {
        [dict setObject:describeStr forKey:@"describeStr"];
    }

    DLYLog(@"方法2Key===%@", eventKey);
    DLYLog(@"方法2Value===%@", dict);
    
    //调用友盟的方法
    [MobClick event:eventKey attributes:dict];
    
}


+ (void)recordAndEventKey:(NSString *)eventKey {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:dateTime forKey:@"dateTime"];
    DLYLog(@"方法1Key===%@", eventKey);
    DLYLog(@"方法1Value===%@", dict);
    
    //调用友盟的方法
    [MobClick event:eventKey attributes:dict];
}

+ (void)beginRecordPageViewWith:(NSString *)pageName {
    [MobClick beginLogPageView:pageName];    
}

+ (void)endRecordPageViewWith:(NSString *)pageName {
    [MobClick endLogPageView:pageName];
}

@end
