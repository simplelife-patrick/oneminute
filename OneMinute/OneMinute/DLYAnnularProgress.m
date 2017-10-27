//
//  DLYAnnularProgress.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYAnnularProgress.h"

@implementation DLYAnnularProgress
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
    }
    
    return self;
}


- (void)drawCycleProgress
{
    if (_animationTime > 0.0) {
        [_progressLayer removeFromSuperlayer];
    }
    CGPoint center = self.center;
    CGFloat radius = _circleRadius;
    CGFloat startA = -M_PI_2 + M_PI * 2 * 0.01;  //设置进度条起点位置
    CGFloat endA = -M_PI_2;  //设置进度条终点位置
    
    //获取环形路径（画一个圆形，填充色透明，设置线框宽度为10，这样就获得了一个环形）
    _progressLayer = [CAShapeLayer layer];//创建一个track shape layer
    _progressLayer.frame = self.bounds;
    _progressLayer.fillColor = _fillColor ? _fillColor.CGColor : [UIColor clearColor].CGColor;//填充色为无色
    _progressLayer.strokeColor = _lineColor ? _lineColor.CGColor : RGB(255, 0, 0).CGColor;//指定path的渲染颜色,这里可以设置任意不透明颜色
    _progressLayer.opacity = 1; //背景颜色的透明度
    _progressLayer.lineCap = kCALineCapRound;//指定线的边缘是圆的
    _progressLayer.lineWidth =  _lineWidth ? _lineWidth : 2.0;//线的宽度
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];//上面说明过了用来构建圆形
    _progressLayer.path =[path CGPath]; //把path传递給layer，然后layer会处理相应的渲染，整个逻辑和CoreGraph是一致的。
    [self.layer addSublayer:_progressLayer];
    
    if (_animationTime > 0.0) {
        CABasicAnimation *pathAnima = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        pathAnima.duration = _animationTime;
        pathAnima.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        pathAnima.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnima.toValue = [NSNumber numberWithFloat:1.0f];
        pathAnima.fillMode = kCAFillModeForwards;
        pathAnima.removedOnCompletion = NO;
        [_progressLayer addAnimation:pathAnima forKey:@"strokeStartAnimation"];
    }
}

- (void)setAnimationTime:(CGFloat)animationTime
{
    _animationTime = animationTime;
    [self setNeedsDisplay];
}

- (void)drawProgress:(CGFloat )progress
{
    [UIView animateWithDuration:1.0f animations:^{
        _progress =progress;
        
    } completion:^(BOOL finished) {
    }];
    
    _progressLayer.opacity = 0;
    [self setNeedsDisplay];
}

- (void)drawProgress:(CGFloat )progress withColor:(UIColor *)color
{
    [UIView animateWithDuration:1.0f animations:^{
        _progress =progress;
        
    } completion:^(BOOL finished) {
    }];
    
    _progressLayer.strokeColor = color.CGColor;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    
    [self drawCycleProgress];
}



@end

