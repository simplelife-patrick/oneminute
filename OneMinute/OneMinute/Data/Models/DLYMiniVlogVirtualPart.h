//
//  DLYVirtualPart.h
//  OneMinute
//
//  Created by chenzonghai on 27/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMiniVlogPart.h"

@interface DLYMiniVlogVirtualPart : DLYMiniVlogPart

/**
 分段数
 */
@property (nonatomic, strong) NSMutableArray<DLYMiniVlogPart *>                 *partsInfo;

@end
