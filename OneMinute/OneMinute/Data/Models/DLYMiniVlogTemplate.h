//
//  DLYMiniVlogTemplate.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogPart.h"


@interface DLYMiniVlogTemplate : DLYModule

/**
 模板名称
 */
@property (nonatomic, strong) NSString                        *templateId;

/**
 模板标题
 */
@property (nonatomic, strong) NSString                        *templateTitle;

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
@property (nonatomic, strong) NSArray                         <DLYMiniVlogPart *>*parts;
/**
 背景音乐
 */
@property (nonatomic, strong) NSString                        *BGM;

/** 
 字幕1(标题)
 */
@property (nonatomic, strong) NSDictionary                    *subTitle1;

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

 @param templateId 模板名称
 @return 返回模板对象
 */
-(instancetype)initWithTemplateId:(NSString *)templateId;

@end
