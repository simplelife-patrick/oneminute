//
//  DLYAlertView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FPopUpViewDelegate <NSObject>

- (void)deletePopUpViewClick;
- (void)cancelPopUpViewClick;

@end

@interface DLYAlertView : UIView

+(void)showWithMessage : (NSString *)message AndCanelButton : (NSString *)canel andSureButton : (NSString *)sure delegate:(id<FPopUpViewDelegate>)delegate;

@property(weak,nonatomic) id<FPopUpViewDelegate>delegate;

@end
