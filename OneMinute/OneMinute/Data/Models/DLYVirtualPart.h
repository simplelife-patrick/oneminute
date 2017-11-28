//
//  DLYVirtualPart.h
//  OneMinute
//
//  Created by chenzonghai on 27/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogPart.h"

@interface DLYVirtualPart : DLYModule

/**
 拍摄时长
 */
@property (nonatomic, copy)   NSString                      *duration;

/**
 分段数
 */
@property (nonatomic, assign) NSInteger                     partCount;

- (void) combinDurationWithParts:(NSArray<DLYMiniVlogPart *> *)parts;

@end
