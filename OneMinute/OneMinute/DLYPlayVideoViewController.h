//
//  DLYPlayVideoViewController.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYBaseViewController.h"
#import "DLYMiniVlogPart.h"

@interface DLYPlayVideoViewController : DLYBaseViewController


@property (strong, nonatomic) void (^DismissBlock)();
@property (nonatomic, assign) BOOL isAll;
@property (nonatomic, strong) NSURL *playUrl;
@property (nonatomic, assign) BOOL isSuccess;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, assign) NSInteger beforeState;
@property (nonatomic, copy) NSArray<DLYMiniVlogPart *>   *moviePaths;  // 录制的原始视频数组

@end
