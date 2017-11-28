//
//  DLYMiniVlogPart.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYVideoTransition.h"


/**
 片段类型

 - DLYMiniVlogPartTypeNormal: 标准片段
 - DLYMiniVlogPartTypeVirtual: 虚拟片段
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogPartType)
{
    DLYMiniVlogPartTypeNormal = 0,
    DLYMiniVlogPartTypeVirtual
};

/**
 拍摄类型

 - DLYMiniVlogRecordTypeNormal: 正常
 - DLYMiniVlogRecordTypeSlomo: 慢动作
 - DLYMiniVlogRecordTypeTimelapse: 延时
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogRecordType)
{
    DLYMiniVlogRecordTypeNormal = 0,
    DLYMiniVlogRecordTypeSlomo,
    DLYMiniVlogRecordTypeTimelapse
};

/**
 音轨方案

 - DLYMiniVlogAudioTypeMusic: 空镜
 - DLYMiniVlogAudioTypeNarrate: 人声
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogAudioType)
{
    DLYMiniVlogAudioTypeMusic = 0,
    DLYMiniVlogAudioTypeNarrate,
};


@interface DLYMiniVlogPart : DLYModule

/**
 片段地址
 */
@property (nonatomic, strong) NSURL                         *partUrl;

/**
 拍摄时长
 */
@property (nonatomic, copy)   NSString                      *duration;

/**
 片段显示时长
 */
@property (nonatomic, copy)   NSString                      *partTime;

/**
 拍摄状态
 */
@property (nonatomic, copy)   NSString                      *recordStatus;

/**
 准备拍摄
 */
@property (nonatomic, copy)   NSString                      *prepareRecord;

#pragma mark - 需要在模板脚本中读取的属性 -

/**
 片段类型
 */
@property (nonatomic, assign) NSInteger                     partType;

/**
 片段序号
 */
@property (nonatomic, assign) NSInteger                     partNum;
/**
 是否合并片段
 */
@property (nonatomic, assign) BOOL                          ifCombin;

/**
 配音开始时间
 */
@property (nonatomic, strong) NSString                      *dubStartTime;

/**
 配音结束时间
 */
@property (nonatomic, strong) NSString                      *dubStopTime;

/**
 拍摄类型
 */
@property (nonatomic, assign) DLYMiniVlogRecordType         recordType;

/**
 音轨方案
 */
@property (nonatomic, assign) DLYMiniVlogAudioType          soundType;

/**
 BGM音量
 */
@property (nonatomic, assign) float                         BGMVolume;
/**
 转场效果类型
 */
@property (nonatomic, assign) DLYVideoTransitionType        transitionType;

/**
 拍摄指导
 */
@property (nonatomic, strong) NSString                      *shootGuide;

#pragma mark - 暂时保留的属性 -
/**
 字幕
 */
@property (nonatomic, strong) NSString                      *subtitle;

@end
