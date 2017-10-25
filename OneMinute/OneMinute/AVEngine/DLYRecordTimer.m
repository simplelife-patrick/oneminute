//
//  DLYRecordTimer.m
//  OneMinute
//
//  Created by chenzonghai on 25/10/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYRecordTimer.h"

@interface DLYRecordTimer()
{
    
}

@property (nonatomic, assign) NSTimeInterval period;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval tickRemain;
@property (nonatomic, strong) NSThread* tickThread;
@property (nonatomic, assign) BOOL hasTickedYet;

@property (nonatomic, assign) NSTimeInterval startIntervalDiff;
@property (nonatomic, assign) NSTimeInterval currentIntervalDiff;
@property (nonatomic, assign) NSTimeInterval stopIntervalDiff;

@end

@implementation DLYRecordTimer

-(instancetype) initWithPeriod:(NSTimeInterval) period duration:(NSTimeInterval) duration
{
    if (self == [super init])
    {
        self.period = period;
        self.duration = duration;
        self.tickRemain = self.duration;
    }
    
    return self;
}

-(void) startTick
{
    if(nil == _tickThread)
    {
        _tickThread = [[NSThread alloc] initWithTarget:self selector:@selector(_tick) object:nil];
        _tickThread.threadPriority = 1.0f;
        [_tickThread start];
        
        [self performSelector:@selector(_bang) withObject:nil afterDelay:self.duration];
    }
    else
    {
    }
}

-(void) _bang
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(self.timerDelegate)
        {
            self.tickRemain = 0;
            [self.timerDelegate businessFinished:self.tickRemain];
        }
    });
    
    [self.tickThread cancel];
    
    NSDate* now = [NSDate date];
    NSTimeInterval diff = now.timeIntervalSinceReferenceDate - self.startIntervalDiff - self.duration;
}

-(void) _tick
{
    if(!self.hasTickedYet)
    {
        NSDate* now = [NSDate date];
        self.startIntervalDiff = now.timeIntervalSinceReferenceDate;
        self.currentIntervalDiff = self.startIntervalDiff;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(self.timerDelegate)
            {
                [self.timerDelegate timerAndBusinessStarted:self.tickRemain];
            }
        });
        
        self.hasTickedYet = YES;
    }
    
    BOOL tickCondition = [self _checkTickCondition];
    BOOL loopCondition = tickCondition;
    NSTimeInterval sleepInterval = self.period;
    while (loopCondition && ![self.tickThread isCancelled])
    {
        sleepInterval = (self.tickRemain >= self.period) ? self.period : self.tickRemain;
        [NSThread sleepForTimeInterval:sleepInterval];
        self.tickRemain = self.tickRemain - self.period;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(self.timerDelegate)
            {
                [self.timerDelegate timerTicked:self.tickRemain];
            }
        });
        
        BOOL remainCondition = (0 < self.tickRemain);
        loopCondition = remainCondition;
        if(loopCondition)
        {
            NSDate* now = [NSDate date];
            NSTimeInterval diff = now.timeIntervalSinceReferenceDate - self.currentIntervalDiff - sleepInterval;
            self.currentIntervalDiff = now.timeIntervalSinceReferenceDate;
        }
    }
    
    self.tickRemain = 0;
    NSDate* now = [NSDate date];
    self.stopIntervalDiff = now.timeIntervalSinceReferenceDate;
    NSTimeInterval diff = self.stopIntervalDiff - self.currentIntervalDiff - sleepInterval;
    NSTimeInterval totalDiff = self.stopIntervalDiff - self.startIntervalDiff - self.duration;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(self.timerDelegate)
        {
            [self.timerDelegate timerStopped:self.tickRemain];
        }
    });
}
-(void) cancelTick
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(self.timerDelegate)
        {
            [self.timerDelegate businessCanceled:self.tickRemain];
        }
    });
    
    [_tickThread cancel];
}

-(BOOL) _checkTickCondition
{
    BOOL flag = NO;
    
    flag = (0 < self.period && 0 < self.duration && self.period <= self.duration) ? YES : NO;
    
    return flag;
}

-(NSString*) _timeStringWithDate:(NSDate*) date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:date];
    
    return dateTime;
}


@end
