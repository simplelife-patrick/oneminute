//
//  DLYRecordTimer.h
//  OneMinute
//
//  Created by chenzonghai on 25/10/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DLYRecordTimerDelegate

-(void)timerAndBusinessStarted:(NSTimeInterval) time;
-(void)timerTicked:(NSTimeInterval) time;
-(void)timerStopped:(NSTimeInterval) time;
-(void)businessFinished:(NSTimeInterval) time;

@end

@interface DLYRecordTimer : NSObject

@property (nonatomic, weak) id<DLYRecordTimerDelegate> timerDelegate;

-(instancetype) initWithPeriod:(NSTimeInterval) period duration:(NSTimeInterval) duration;
-(void) startTick;


@end
