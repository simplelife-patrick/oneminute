//
//  SceneView.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol selectSceneDelegate <NSObject>

- (void)onClickCancelSelect:(UIButton *)sender;
- (void)onClickSeeSceneVideo:(UIButton *)sender;
- (void)onClickSelectScene:(UIButton *)sender;

@end

@interface SceneView : UIView

@property (nonatomic, strong) NSMutableArray *typeModelArray;

@property (nonatomic,weak)id<selectSceneDelegate>  delegate;    //代理方法


@end
