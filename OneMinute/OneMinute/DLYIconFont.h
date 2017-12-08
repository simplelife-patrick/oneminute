//
//  DLYIconFont.h
//  TestIconfont
//
//  Created by 陈立勇 on 2017/11/3.
//  Copyright © 2017年 t. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DLYIFName) {
    IFSuccessful               = 0xe66b,       // 成功
    IFPlayVideo                = 0xe66c,       // 播放视频
    IFStopVideo                = 0xe66a,       // 停止播放视频
    IFPrimary                  = 0xe67e,       // 入门操作
    IFSecondary                = 0xe67d,       // 进阶操作
    IFAdvanced                 = 0xe682,       // 熟练操作
    IFGoNorth                  = 0xe683,       // 一路向北
    IFMyMaldives               = 0xe67b,       // 马尔代夫
    IFBigMeal                  = 0xe67f,       // 一顿大餐
    IFAfternoonTea             = 0xe678,       // 轻松吃吃
    IFDelicious                = 0xe680,       // 人间美味
    IFColorfulLife             = 0xe684,       // 过年好
    IFSunSetBeach              = 0xe67c,       // 大白天的
    IFYoungOuting              = 0xe679,       // 青春壮游
    IFSpiritTerritory          = 0xe681,       // 诗与远方
    IFFlashOff                 = 0xe600,       // 闪光灯关闭
    IFToggleLens               = 0xe668,       // 切换摄像头
    IFRecord                   = 0xe664,       // 录制视频
    IFDeleteAll                = 0xe669,       // 删除全部视频(垃圾桶)
    IFDetelePart               = 0xe667,       // 删除拍摄片段
    IFFlashOn                  = 0xe601,       // 闪光灯开启
    IFFastLens                 = 0xe670,       // 快镜头
    IFSlowLens                 = 0xe66f,       // 慢镜头
    IFStopToggle               = 0xe685,       // 相机禁止切换
    IFShut                     = 0xe666,       // 关闭
    IFShowVideo                = 0xe63f,       // 表示观看样片
    IFSure                     = 0xe602,       // 确定按钮
    IFBack                     = 0xe64d,       // 返回
    IFMute                     = 0xe663,       // 静音
    IFNoFilter                 = 0xe61d,       //没有滤镜
    IFFilter                   = 0xe686,       //滤镜
};

@interface DLYIconFont : NSObject

/* 生成字体库文字 */
+ (NSString*)stringWithIconName:(DLYIFName)iconName;

@end
