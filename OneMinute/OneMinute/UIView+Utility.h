//
//  UIView+Utility.h
//  Weipaimai
//
//  Created by peng jiang on 10/1/14.
//  Copyright (c) 2014 peng jiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Utility)

@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat bottom;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGSize size;
@property (nonatomic,assign) CGFloat x;
@property (nonatomic,assign) CGFloat y;

// data refresh
@property (nonatomic, assign) BOOL dataRefreshed;

@end
