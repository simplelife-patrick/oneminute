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
    BOOL isStop;
}

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UILabel *titlelabel;
@property (nonatomic, strong) NSTimer *flashTimer;
@property (nonatomic, assign) NSInteger num;

@end

@implementation DLYIndicatorView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self createIndicatorView];
    }
    return self;
}

+ (instancetype)sharedIndicatorView{
    
    static DLYIndicatorView *indicatorView;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indicatorView = [[DLYIndicatorView alloc] init];
    });
    return indicatorView;
}

- (void)createIndicatorView {
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    //背景图片
    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];
    self.mainView.centerX = self.width / 2;
    self.mainView.centerY = self.centerY;
    self.mainView.backgroundColor = [UIColor colorWithHexString:@"#000000" withAlpha:0.8];
    self.mainView.layer.cornerRadius = self.mainView.width / 2;
    self.mainView.clipsToBounds = YES;
    [self addSubview:self.mainView];
    
    //文字说明
    self.titlelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 98, 150, 20)];
    self.titlelabel.centerX = 90;
    self.titlelabel.textColor = RGB(153, 153, 153);
    self.titlelabel.font = FONT_SYSTEM(14);
    self.titlelabel.textAlignment = NSTextAlignmentCenter;
    self.titlelabel.text = @"处理中,请稍后";
    [self.mainView addSubview:self.titlelabel];
    
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
    
    self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(flashAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSRunLoopCommonModes];
    [self.flashTimer setFireDate:[NSDate distantFuture]];
    self.num = 0;
    self.hidden = YES;
    self.isFlashAnimating = NO;
}

- (void)flashAnimation {
    self.num ++;
    int i = self.num % 6;
    
    if (self.num >= 6 && isStop) {
        [self stopFlashAnimating];
        return;
    }
    
    UIView *view = (UIView *)[self viewWithTag:30000 + i];
    view.alpha = 1;
    UIView *oldView = (UIView *)[self viewWithTag:oldTag];
    oldView.alpha = 0.2;
    oldTag = 30000 + i;
}

- (void)startFlashAnimatingWithTitle:(NSString *)title {
    NSString *newStr = [title stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (newStr.length <= 0) {
        self.titlelabel.text = @"处理中,请稍后";
    }else{
        self.titlelabel.text = title;
    }
    if (self.isHidden) {
        self.hidden = NO;
    }
    self.isFlashAnimating = YES;
    [self.flashTimer setFireDate:[NSDate distantPast]];
}

- (void)stopFlashAnimating {
    if (self.num < 6) {
        isStop = YES;
        return;
    }
    isStop = NO;
    if (!self.isHidden) {
        self.hidden = YES;
    }
    self.isFlashAnimating = NO;
    self.num = 0;
    [self.flashTimer setFireDate:[NSDate distantFuture]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(indicatorViewstopFlashAnimating)]) {
        [self.delegate indicatorViewstopFlashAnimating];
    }
}

@end

