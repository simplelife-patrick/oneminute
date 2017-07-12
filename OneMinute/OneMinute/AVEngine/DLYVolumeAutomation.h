//
//  DLYVolumeAutomation.h
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYVolumeAutomation : NSObject

+ (id)volumeAutomationWithTimeRange:(CMTimeRange)timeRange
                        startVolume:(CGFloat)startVolume
                          endVolume:(CGFloat)endVolume;

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic) CGFloat startVolume;
@property (nonatomic) CGFloat endVolume;

@end
