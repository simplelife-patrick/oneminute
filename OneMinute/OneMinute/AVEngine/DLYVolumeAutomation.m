
//
//  DLYVolumeAutomation.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYVolumeAutomation.h"

@implementation DLYVolumeAutomation

+ (id)volumeAutomationWithTimeRange:(CMTimeRange)timeRange
                        startVolume:(CGFloat)startVolume
                          endVolume:(CGFloat)endVolume {
    
    DLYVolumeAutomation *automation = [[DLYVolumeAutomation alloc] init];
    automation.timeRange = timeRange;
    automation.startVolume = startVolume;
    automation.endVolume = endVolume;
    return automation;
}

@end
