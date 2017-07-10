//
//  DLYMiniVlogTemplate.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"

/**
 模板类型

 - DLYTemplateUniversal: 通用
 - DLYTemplateGourmandism: 美食主义
 - DLYTemplateTraveler: 旅行家
 - DLYTemplateTypeScenery: 美景
 - DLYTemplateTypeHumanity: 人文
 */
typedef NS_ENUM(NSInteger,DLYMiniVlogTemplateType)
{
    DLYMiniVlogTemplateTypeUniversal = 0,
    DLYMiniVlogTemplateTypeGourmandism,
    DLYMiniVlogTemplateTypeTraveler,
    DLYMiniVlogTemplateTypeScenery,
    DLYMiniVlogTemplateTypeHumanity
};

@interface DLYMiniVlogTemplate : DLYModule

/**
 模板编号
 */
@property (nonatomic, strong) NSString                *templateNum;

/**
 模板类型
 */
@property (nonatomic, assign) DLYMiniVlogTemplateType         *templateType;

/**
 模板详情
 */
@property (nonatomic, strong) NSArray                 *parts;

/**
 片头
 */
@property (nonatomic, strong) NSURL                   *videoHeader;

/**
 片尾
 */
@property (nonatomic, strong) NSURL                   *videoTail;

@end
