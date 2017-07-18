//
//  DLYMiniVlogTemplate.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogPart.h"

/**
 模板类型

 - DLYMiniVlogTemplateTypeUniversal: 通用
 - DLYMiniVlogTemplateTypeGourmandism: 美食主义
 - DLYMiniVlogTemplateTypeTraveler: 旅行家
 - DLYMiniVlogTemplateTypeScenery: 美景
 - DLYMiniVlogTemplateTypeHumanity: 人文
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
@property (nonatomic, strong) NSString                        *templateId;

/**
 模板类型
 */
@property (nonatomic, assign) DLYMiniVlogTemplateType         templateType;

/**
 模板详情
 */
@property (nonatomic, strong) NSArray                         <DLYMiniVlogPart *>*parts;
/**
 背景音乐
 */
@property (nonatomic, strong) NSURL                           *BGM;
/**
 片头
 */
@property (nonatomic, strong) NSURL                           *videoHeader;

/**
 片尾
 */
@property (nonatomic, strong) NSURL                           *videoTailer;

/**
 初始化模板

 @param templateName 模板名称
 @return 返回模板对象
 */
-(instancetype)initWithTemplateName:(NSString *)templateName;

@end
