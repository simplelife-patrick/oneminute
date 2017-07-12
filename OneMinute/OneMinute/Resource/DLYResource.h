//
//  DLYResource.h
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"

@interface DLYResource : DLYModule

/**
 获取沙盒Document路径

 @return 返回路径
 */
- (NSString *) getDataPath;
    /**
 加载片头文件

 @param fileName 片头视频文件名称
 */
- (void) loadBVideoHeaderWithFileName:(NSString *)fileName;

/**
 加载片尾文件

 @param fileName 片尾视频文件名称
 */
- (void) loadBVideoTailerWithFileName:(NSString *)fileName;

/**
 加载BGM文件

 @param fileName BGM文件名称
 */
- (void) loadBVideoBGMWithFileName:(NSString *)fileName;

/**
 加载样片视频文件

 @param fileName 样片文件名称
 */
- (void) loadTemplateSampleWithFileName:(NSString *)fileName;

/**
 加载草稿视频片段文件
 */
- (void) loadBDraftParts;


@end
