//
//  DLYAlertView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^DLYAlertViewBlock)(void);

@interface DLYAlertView : UIView

- (instancetype)initWithMessage : (NSString *)message andCancelButton : (NSString *)canel andSureButton : (NSString *)sure;

- (instancetype)initWithMessage : (NSString *)message withSureButton : (NSString *)sure;

@property (readwrite, copy) DLYAlertViewBlock cancelButtonAction;
@property (readwrite, copy) DLYAlertViewBlock sureButtonAction;


@end
