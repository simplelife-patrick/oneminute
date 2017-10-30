//
//  DLYIndicatorView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DLYIndicatorViewDelegate <NSObject>

- (void)indicatorViewStopFlashAnimating;

@end

@interface DLYIndicatorView : UIView

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, assign) BOOL isFlashAnimating;

+ (instancetype)sharedIndicatorView;

- (void)startFlashAnimatingWithTitle:(NSString *)title;

- (void)stopFlashAnimating;

@property (nonatomic, weak) id<DLYIndicatorViewDelegate> delegate;

@end
