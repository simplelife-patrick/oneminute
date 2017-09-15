//
//  DLYAsyncQueue.h
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import <Foundation/Foundation.h>


#define SYNC_LOCK_NEW(lock, timeout, startTimestamp, endTimestamp) \
__block NSCondition* lock = [[NSCondition alloc] init]; \
NSDate* startTimestamp = [NSDate date]; \
NSDate* endTimestamp = [NSDate dateWithTimeInterval:timeout sinceDate:startTimestamp];

#define SYNC_LOCK_START(lock) \
[lock lock]; \
[lock signal]; \
[lock unlock];

#define SYNC_LOCK_TIMEOUT(lock, onTime, endTimestamp) \
[lock lock]; \
BOOL onTime = [lock waitUntilDate:endTimestamp]; \
[lock unlock];


@interface DLYAsyncQueue : NSObject

- (instancetype)initWithName:(NSString *)name maxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount;

/**
 *  异步执行任务
 *
 *  @param block 任务block
 */
- (void)asyncWithBlock:(void (^)(void))block;

/**
 *  直接添加一个operation
 */
- (void)addOperation:(NSOperation *)operation;

@end
