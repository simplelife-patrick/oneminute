//
//  DLYAsyncQueue.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYAsyncQueue.h"


@interface DLYAsyncQueue()
{
    
}

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end


@implementation DLYAsyncQueue

- (instancetype)initWithName:(NSString *)name maxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    self = [super init];
    if (self)
    {
        NSOperationQueue *optQueue = [[NSOperationQueue alloc] init];
        optQueue.name = name;
        optQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
        
        _operationQueue = optQueue;
    }
    
    return self;
}

- (void)asyncWithBlock:(void (^)(void))block
{
    NSAssert(self.operationQueue, @"operationQueue can not be nil.");
    
    [self.operationQueue addOperationWithBlock:block];
}

- (void)addOperation:(NSOperation *)operation
{
    NSAssert(self.operationQueue, @"operationQueue can not be nil.");
    
    [self.operationQueue addOperation:operation];
}

@end
