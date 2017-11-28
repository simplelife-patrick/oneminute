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
 片头类型

 - DLYMiniVlogHeaderType_A: 片头A
 - DLYMiniVlogHeaderType_B: 片头B
 - DLYMiniVlogHeaderType_C: 片头C
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogHeaderType)
{
    DLYMiniVlogHeaderType_A = 0,
    DLYMiniVlogHeaderType_B,
    DLYMiniVlogHeaderType_C
};

/**
 片尾类型

 - DLYMiniVlogFooterType_A: 片尾A
 - DLYMiniVlogFooterType_B: 片尾B
 - DLYMiniVlogFooterType_C: 片尾C
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogTailerType)
{
    DLYMiniVlogTailerType_A = 0,
    DLYMiniVlogTailerType_B,
    DLYMiniVlogTailerType_C
};

@interface DLYMiniVlogTemplate : DLYModule

/**
 模板名称
 */
@property (nonatomic, strong) NSString                        *templateId;

/**
 模板版本
 */
@property (nonatomic, strong) NSString                        *version;

/**
 模板标题
 */
@property (nonatomic, strong) NSString                        *templateTitle;

/**
 水印日期
 */
@property (nonatomic, strong) NSDictionary                    *dateWaterMark;
/**
 模板描述
 */
@property (nonatomic, strong) NSString                        *templateDescription;

/**
 模板样片名称
 */
@property (nonatomic, strong) NSString                        *sampleVideoName;

/**
 模板详情
 */
@property (nonatomic, strong) NSArray<DLYMiniVlogPart *>      *parts;
/**
 背景音乐
 */
@property (nonatomic, strong) NSString                        *BGM;

/** 
 字幕1(标题)
 */
@property (nonatomic, strong) NSDictionary                    *subTitle1;

/**
 片头类型
 */
@property (nonatomic, assign) DLYMiniVlogHeaderType           videoHeaderType;

/**
 片尾类型
 */
@property (nonatomic, assign) DLYMiniVlogTailerType           videoTailerType;

/**
 初始化模板

 @param templateId 模板名称
 @return 返回模板对象
 */
-(instancetype)initWithTemplateId:(NSString *)templateId;

@end
