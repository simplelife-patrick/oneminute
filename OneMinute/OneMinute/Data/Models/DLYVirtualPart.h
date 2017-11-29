//
//  DLYVirtualPart.h
//  OneMinute
//
//  Created by chenzonghai on 27/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMiniVlogPart.h"

@interface DLYVirtualPart : DLYMiniVlogPart

/**
 分段数
 */
@property (nonatomic, strong) NSMutableArray<DLYVirtualPart *>                 *partsInfo;

@end
