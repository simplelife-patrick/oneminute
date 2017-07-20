//
//  DLYBaseViewController.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLYBaseViewController : UIViewController

@property (nonatomic, assign) NSInteger newState;
@property (nonatomic, assign) NSInteger oldState;


- (void)deviceChangeAndHomeOnTheLeft;

- (void)deviceChangeAndHomeOnTheRight;

@end
