//
//  RecordControlView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLYMiniVlogPart.h"

@protocol RecordControlDelegate <NSObject>

- (void)startRecordBtn:(UIButton *)sender;
//播放某个片段
- (void)onClickPlayPartVideo:(UIButton *)sender;
//删除某个片段
- (void)onClickDeletePartVideo:(UIButton *)sender;
//片段选择
- (void)vedioEpisodeClick:(UIButton *)sender;

@end

@interface RecordControlView : UIView

@property (nonatomic, strong) NSMutableArray *partModelArray;    //数组
@property (nonatomic, strong) UIView *prepareView;          //光标
@property (nonatomic, strong) NSTimer * prepareShootTimer;  //准备拍摄片段闪烁的计时器
@property (nonatomic, strong) UIButton *recordBtn;          //拍摄按钮
@property (nonatomic, strong) UIView *vedioEpisode;         //片段展示底部
@property (nonatomic, strong) UIScrollView *backScrollView; //片段展示滚图
@property (nonatomic, strong) UIView *playView;             //单个片段编辑页面
@property (nonatomic, strong) UIButton *playButton;         //播放单个视频
@property (nonatomic, strong) UIButton *deletePartButton;   //删除单个视频

@property (nonatomic,weak)id<RecordControlDelegate>  delegate;    //代理方法


@end
