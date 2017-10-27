//
//  DLYAnnularProgress.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLYAnnularProgress : UIView


- (id)initWithFrame:(CGRect)frame;
- (void)drawCycleProgress;
- (void)drawProgress:(CGFloat )progress;
- (void)drawProgress:(CGFloat )progress withColor:(UIColor *)color;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat animationTime;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, assign) CGFloat circleRadius;

// 线条宽度，默认为3.0；
@property (nonatomic, assign) CGFloat lineWidth;

// 线条颜色，默认是redColor
@property (nonatomic, strong) UIColor *lineColor;

// 设置填充颜色，默认是clearColor；
@property (nonatomic, strong) UIColor *fillColor;

@end

