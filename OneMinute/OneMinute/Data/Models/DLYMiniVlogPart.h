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
@property (nonatomic, strong) NSString                      *partPath;

/**
 拍摄时长
 */
@property (nonatomic, copy)   NSString                      *duration;

/**
 拍摄状态
 */
@property (nonatomic, copy)   NSString                      *recordStatus;

/**
 准备拍摄
 */
@property (nonatomic, copy)   NSString                      *prepareRecord;

/**
 片段序号
 */
@property (nonatomic, assign) NSInteger                     partNum;

/**
 起始时间
 */
@property (nonatomic, strong) NSString                      *starTime;

/**
 终止时间
 */
@property (nonatomic, strong) NSString                      *stopTime;
    
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
 转场效果类型
 */
@property (nonatomic, assign) DLYVideoTransitionType     transitionType;

/**
 字幕
 */
@property (nonatomic, strong) NSString                  *subtitle;

/**
 滤镜类型名称
 */
@property (nonatomic, strong) NSString                  *filter;

/**
 是否完成拍摄
 */
@property (nonatomic, assign) BOOL                      *isRecordFinished;


@end
