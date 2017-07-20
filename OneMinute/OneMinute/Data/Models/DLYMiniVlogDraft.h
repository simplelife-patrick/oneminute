//
//  DLYMiniVlogDraft.h
//  OneMinute
//
//  Created by chenzonghai on 13/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogTemplate.h"

@interface DLYMiniVlogDraft : DLYModule

/**
 草稿的模板类型
 */
@property (nonatomic, assign) DLYMiniVlogTemplateType                templateType;

/**
 草稿片段
 */
@property (nonatomic, copy) NSArray                                  *parts;

@end
