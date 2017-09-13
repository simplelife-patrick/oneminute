//
//  DLYIndicatorView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLYIndicatorView : UIView

@property (nonatomic, strong) UILabel *titlelabel;

- (void)startFlashAnimating;

- (void)stopFlashAnimating;

@end
