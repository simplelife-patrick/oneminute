//
//  ShootView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLYAnnularProgress.h"

@interface ShootView : UIView

@property (nonatomic, strong) UIButton *cancelButton;       //取消拍摄
@property (nonatomic, strong) UILabel *timeNumber;          //倒计时显示label
@property (nonatomic, strong) UIButton *completeButton;     //拍摄单个片段完成
@property (nonatomic, strong) UIImageView *warningIcon;     //拍摄指导
@property (nonatomic, strong) UILabel *shootGuide;          //拍摄指导
@property (nonatomic, strong) DLYAnnularProgress * progressView;    //环形进度条
@property (nonatomic, strong) UIView * timeView;            //进度条

@end
