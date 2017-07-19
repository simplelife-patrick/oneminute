//
//  ShootView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "ShootView.h"

@implementation ShootView


- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self createUI];
    }
    return self;
}

- (void)createUI {

    self.backgroundColor = RGBA(247, 247, 247,0);
    self.alpha = 0;

    self.warningIcon = [[UIImageView alloc]initWithFrame:CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32)];
    self.warningIcon.hidden = YES;
    self.warningIcon.image = [UIImage imageWithIcon:@"\U0000e663" inFont:ICONFONT size:32 color:[UIColor redColor]];
    [self.shootView addSubview:self.warningIcon];
    
    self.shootGuide = [[UILabel alloc] init];
    if (self.newState == 1) {
        self.shootGuide.frame = CGRectMake(0, SCREEN_HEIGHT - 49, 270, 30);
        self.shootGuide.centerX = _shootView.centerX;
        self.shootGuide.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.shootGuide.frame = CGRectMake(0, 19, 270, 30);
        self.shootGuide.centerX = _shootView.centerX;
        self.shootGuide.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.shootGuide.backgroundColor = RGBA(0, 0, 0, 0.7);
    self.shootGuide.text = @"拍摄指导：请保持光线充足";
    self.shootGuide.textColor = RGB(255, 255, 255);
    self.shootGuide.font = FONT_SYSTEM(14);
    self.shootGuide.textAlignment = NSTextAlignmentCenter;
    [_shootView addSubview:self.shootGuide];
    
    _timeView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 70, 0, 60, 60)];
    _timeView.centerY = self.shootView.centerY;
    [self.shootView addSubview:_timeView];
    
    self.cancelButton = [[UIButton alloc] init];
    if (self.newState == 1) {
        self.cancelButton.frame = CGRectMake(0, _timeView.bottom + 10, 30, 15);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(0);
        
    }else {
        self.cancelButton.frame = CGRectMake(0, _timeView.top - 25, 30, 15);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(M_PI);
    }
    
    [self.cancelButton addTarget:self action:@selector(onClickCancelClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = FONT_SYSTEM(14);
    self.cancelButton.hidden = YES;
    [_shootView addSubview:self.cancelButton];
    
    _progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, _timeView.width, _timeView.height)];
    if (self.newState == 1) {
        self.progressView.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.progressView.transform = CGAffineTransformMakeRotation(M_PI);
    }
    _progressView.progress = 0.01;
    _progressView.circleRadius = 28;
    [_timeView addSubview:_progressView];
    
    //完成图片
    self.completeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.timeView.width, self.timeView.height)];
    self.completeButton.layer.borderWidth = 3.0;
    self.completeButton.layer.borderColor = RGB(255, 0, 0).CGColor;
    self.completeButton.layer.cornerRadius = self.timeView.width / 2.0;
    self.completeButton.clipsToBounds = YES;
    [self.completeButton setImage:[UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:30 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
    self.completeButton.hidden = YES;
    [_timeView addSubview:self.completeButton];
    
    self.timeNumber = [[UILabel alloc]initWithFrame:CGRectMake(3, 3, 54, 54)];
    if (self.newState == 1) {
        self.timeNumber.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.timeNumber.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.timeNumber.textColor = RGB(51, 51, 51);
    self.timeNumber.text = @"10";
    self.timeNumber.font = FONT_SYSTEM(20);
    self.timeNumber.textAlignment = NSTextAlignmentCenter;
    self.timeNumber.backgroundColor = RGBA(0, 0, 0, 0.3);
    self.timeNumber.layer.cornerRadius = 27
    ;
    self.timeNumber.clipsToBounds = YES;
    [_timeView addSubview:self.timeNumber];
    
    _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(shootAction) userInfo:nil repeats:YES];
    if (self.newState == 1) {
        self.cancelButton.frame = CGRectMake(0, _timeView.bottom + 10, 30, 15);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(0);
        
    }else {
        self.cancelButton.frame = CGRectMake(0, _timeView.top - 25, 30, 15);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(M_PI);
    }
    
    self.cancelButton.hidden = NO;
    

}


@end
