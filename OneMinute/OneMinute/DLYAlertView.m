//
//  DLYAlertView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYAlertView.h"


@implementation DLYAlertView

- (instancetype)initWithMessage : (NSString *)message andCancelButton : (NSString *)canel andSureButton : (NSString *)sure {
    
    self = [super initWithFrame:CGRectMake(0, 0, self.width, self.height)];
    if (self) {
        // Initialization code
        
        UIViewController *result = nil;
        
        UIWindow * window = [[UIApplication sharedApplication] keyWindow];
        if (window.windowLevel != UIWindowLevelNormal)
        {
            NSArray *windows = [[UIApplication sharedApplication] windows];
            for(UIWindow * tmpWin in windows)
            {
                if (tmpWin.windowLevel == UIWindowLevelNormal)
                {
                    window = tmpWin;
                    break;
                }
            }
        }
        
        UIView *frontView = [[window subviews] objectAtIndex:0];
        id nextResponder = [frontView nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            result = nextResponder;
        }else
        {
            result = window.rootViewController;
        }
        
        self.frame = window.bounds;
        self.backgroundColor = [UIColor colorWithRed:0.0/255 green:0.0/255 blue:0.0/255 alpha:0.1];
        [result.view addSubview:self];
        
        UIView * popView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 111)];
        popView.backgroundColor = RGBA(0, 0, 0, 0.5);
        popView.center = self.center;
        [self addSubview:popView];
        
        UILabel * messageLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 15, popView.width - 10, 35)];
        messageLabel.numberOfLines = 0;
        messageLabel.text = message;
        messageLabel.textColor = RGB(255, 255, 255);
        messageLabel.font = FONT_SYSTEM(14);
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [popView addSubview:messageLabel];
        
        UIView * line = [[UIView alloc]initWithFrame:CGRectMake(0, messageLabel.bottom + 16, popView.width, 1)];
        line.backgroundColor = [UIColor whiteColor];
        [popView addSubview:line];
        
        UIButton * canelButton = [[UIButton alloc]initWithFrame:CGRectMake(0, line.bottom, popView.width/2, 40)];
        [canelButton setTitle:canel forState:UIControlStateNormal];
        [canelButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
        canelButton.tag = 10;
        canelButton.titleLabel.font = FONT_SYSTEM(16);
        [canelButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [popView addSubview:canelButton];
        
        UIView * centerLine = [[UIView alloc]initWithFrame:CGRectMake(popView.width/2, line.bottom, 1, 40)];
        centerLine.backgroundColor = [UIColor whiteColor];
        [popView addSubview:centerLine];
        
        
        UIButton * sureButton = [[UIButton alloc]initWithFrame:CGRectMake(popView.width/2+1, line.bottom, popView.width/2-1, 40)];
        sureButton.tag = 11;
        [sureButton setTitle:sure forState:UIControlStateNormal];
        [sureButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
        sureButton.titleLabel.font = FONT_SYSTEM(16);
        [sureButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [popView addSubview:sureButton];
        
    }
    return self;
}


-(void)buttonClick:(id)sender
{
    UIButton * button = (UIButton *)sender;
    if(button.tag == 10)
    {//取消按钮
        if (self.cancelButtonAction) {
            self.cancelButtonAction();
        }
        
    }else if(button.tag == 11)
    {//确定按钮
        if (self.sureButtonAction) {
            self.sureButtonAction();
        }
    }
    [self removeFromSuperview];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
