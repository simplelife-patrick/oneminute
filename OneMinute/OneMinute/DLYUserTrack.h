//
//  DLYUserTrack.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/10/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYUserTrack : NSObject

+ (void)recordAndEventKey:(NSString *)eventKey andDescribeStr:(NSString *)describeStr andPartNum:(NSString *)partNum;
+ (void)recordAndEventKey:(NSString *)eventKey andDescribeStr:(NSString *)describeStr;
+ (void)recordAndEventKey:(NSString *)eventKey;

+ (void)beginRecordPageViewWith:(NSString *)pageName;
+ (void)endRecordPageViewWith:(NSString *)pageName;

@end
