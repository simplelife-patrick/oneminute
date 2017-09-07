//
//  DLYIndicatorView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYIndicatorView.h"

@interface DLYIndicatorView (){
    //上一个
    NSInteger oldTag;
}

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UILabel *titlelabel;

@property (nonatomic, strong) NSTimer *flashTimer;
@property (nonatomic, assign) NSInteger num;

@end

@implementation DLYIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self createIndicatorView];
    }
    return self;
}

- (void)createIndicatorView {

    //背景图片
    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];
    self.mainView.centerX = self.width / 2;
    self.mainView.backgroundColor = RGB(0, 0, 0);
    self.mainView.layer.cornerRadius = self.width / 2;
    self.mainView.clipsToBounds = YES;
    [self addSubview:self.mainView];
    
    //文字说明
    self.titlelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 84, 20)];
    self.titlelabel.top = self.mainView.bottom + 9;
    self.titlelabel.centerX = self.width / 2;
    self.titlelabel.textColor = RGB(153, 153, 153);
    self.titlelabel.font = FONT_SYSTEM(14);
    self.titlelabel.textAlignment = NSTextAlignmentCenter;
    self.titlelabel.text = @"正在成片中...";
    [self addSubview:self.titlelabel];
    
    for (int i = 0; i < 6; i++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(25 + 22 * i, 87, 20, 6)];
        view.tag = 30000 + i;
        view.backgroundColor = RGB(255, 255, 255);
        if (i == 0) {
            view.alpha = 1;
            oldTag = 30000;
        }else {
            view.alpha = 0.2;
        }
        [self.mainView addSubview:view];
    }
    
    self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(flashAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSRunLoopCommonModes];
    [self.flashTimer setFireDate:[NSDate distantFuture]];
    self.num = 0;

}

- (void)flashAnimation {
    self.num ++;
    int i = self.num % 6;
    
    UIView *view = (UIView *)[self viewWithTag:30000 + i];
    view.alpha = 1;
    UIView *oldView = (UIView *)[self viewWithTag:oldTag];
    oldView.alpha = 0.2;
    oldTag = 30000 + i;
}

- (void)startFlashAnimating {
    [self.flashTimer setFireDate:[NSDate distantPast]];
}

- (void)stopFlashAnimating {
    [self.flashTimer invalidate];
    self.flashTimer = nil;
}


@end
