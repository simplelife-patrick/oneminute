//
//  DLYMiniVlogPart.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"

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

 - DLYMiniVlogAudioTypeNormal: 空镜
 - DLYMiniVlogAudioTypeNarrate: 人声
 - DLYMiniVlogAudioTypeMusic: 配乐
 */
typedef NS_ENUM(NSInteger, DLYMiniVlogAudioType)
{
    DLYMiniVlogAudioTypeNormal = 0,
    DLYMiniVlogAudioTypeNarrate,
    DLYMiniVlogAudioTypeMusic
};

/**
 转场动画效果

 - DLYMiniVlogTransitionTypeDissolve: 溶解
 - DLYMiniVlogTransitionTypePush: 推出
 - DLYMiniVlogTransitionTypeClockwiseRotate: 顺时针旋转
 - DLYMiniVlogTransitionTypeZoomIn: 由大缩放到小
 - DLYMiniVlogTransitionTypeZoomOut: 由小缩放到大
 */
typedef NS_ENUM(NSInteger,DLYMiniVlogTransitionType)
{
    DLYMiniVlogTransitionTypeDissolve = 0,
    DLYMiniVlogTransitionTypePush,
    DLYMiniVlogTransitionTypeClockwiseRotate,
    DLYMiniVlogTransitionTypeZoomIn,
    DLYMiniVlogTransitionTypeZoomOut
};

@interface DLYMiniVlogPart : DLYModule

/**
 拍摄状态
 */
@property (nonatomic, copy)   NSString                      *shootStatus;

/**
 准备拍摄
 */
@property (nonatomic, copy)   NSString                      *prepareShoot;

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
@property (nonatomic, assign) DLYMiniVlogTransitionType     transitionType;

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
