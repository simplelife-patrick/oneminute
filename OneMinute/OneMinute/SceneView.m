//
//  SceneView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "SceneView.h"


@interface SceneView (){

    //记录选中的样片类型
    NSInteger selectType;

}

@end

@implementation SceneView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self createUI];
    }
    return self;
}

- (void)createUI {

    self.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.alpha = 0;
    
    UIButton * scenceDisapper = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 14, 14)];
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [scenceDisapper setHitEdgeInsets:edgeInsets];
    [scenceDisapper setImage:[UIImage imageWithIcon:@"\U0000e666" inFont:ICONFONT size:14 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [scenceDisapper addTarget:self action:@selector(onTouchCancelSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:scenceDisapper];
    
    UIView * typeView = [[UIView alloc]initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 80, 162 * SCALE_HEIGHT)];
    typeView.centerY = self.centerY;
    [self addSubview:typeView];
    UIScrollView * typeScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, typeView.width, typeView.height)];
    typeScrollView.showsVerticalScrollIndicator = NO;
    typeScrollView.showsHorizontalScrollIndicator = NO;
    typeScrollView.bounces = NO;
    [typeView addSubview:typeScrollView];
    
    float width = (typeView.width - 40)/5;
    typeScrollView.contentSize = CGSizeMake(width * self.typeModelArray.count + 10 * (self.typeModelArray.count - 1), typeScrollView.height);
    for(int i = 0; i < self.typeModelArray.count; i ++)
    {
        NSDictionary * dcitModel = self.typeModelArray[i];
        UIView * view = [[UIView alloc]initWithFrame:CGRectMake((width + 10) * i, 0, width, typeView.height)];
        view.layer.cornerRadius = 5;
        view.clipsToBounds = YES;
        view.tag = 101 + i;
        [typeScrollView addSubview:view];
        
        UILabel * typeName = [[UILabel alloc]initWithFrame:CGRectMake(12, 19, 42, 21)];
        typeName.text = dcitModel[@"typeName"];
        typeName.textColor = RGB(255, 255, 255);
        typeName.font = FONT_BOLD(20);
        [view addSubview:typeName];
        
        UIImageView * selectImage = [[UIImageView alloc]initWithFrame:CGRectMake(view.width - 31, 20, 20, 16)];
        selectImage.image = [UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)];
        selectImage.tag = 10 + i;
        [view addSubview:selectImage];
        
        UILabel * detailLabel = [[UILabel alloc]initWithFrame:CGRectMake(11, typeName.bottom + 15, view.width - 26, 34)];
        detailLabel.text = dcitModel[@"typeIntroduce"];
        detailLabel.font = FONT_SYSTEM(14);
        detailLabel.textColor = RGBA(255, 255, 255, 0.6);
        detailLabel.numberOfLines = 2;
        [view addSubview:detailLabel];
        
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, view.width, view.height)];
        button.tag = 300 + i;
        [button addTarget:self action:@selector(onTouchSceneView:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        UIButton * seeRush = [[UIButton alloc]initWithFrame:CGRectMake(0, view.height - 30, view.width - 10 * SCALE_WIDTH, 15)];
        [seeRush setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:12 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [seeRush setTitle:@"观看样片" forState:UIControlStateNormal];
        [seeRush setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
        seeRush.titleLabel.font = FONT_SYSTEM(12);
        seeRush.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        seeRush.tag = 400 + i;
        [seeRush addTarget:self action:@selector(onTouchSceneView:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:seeRush];
        
        
        if(i == selectType)
        {
            view.backgroundColor = RGB(24, 160, 230);
            selectImage.hidden = NO;
        }else
        {
            view.backgroundColor = RGBA(0, 0, 0, 0.5);
            selectImage.hidden = YES;
        }
    }



}


#pragma mark ==== 代理方法
- (void)onTouchCancelSelect:(UIButton *)sender {

    if ([self.delegate respondsToSelector:@selector(onClickCancelSelect:)]) {
        [self.delegate onClickCancelSelect:sender];
    }
}

- (void)onTouchSceneView:(UIButton *)sender {
    
    UIButton * button = (UIButton *)sender;
    NSInteger selectNum = button.tag/100;
    if(selectNum == 4)
    {//点击的事观看样片
        if ([self.delegate respondsToSelector:@selector(onClickSeeSceneVideo:)]) {
            [self.delegate onClickSeeSceneVideo:sender];
        }
    }else if(selectNum == 3)
    {//点击的事某个片段
        if ([self.delegate respondsToSelector:@selector(onClickSelectScene:)]) {
            [self.delegate onClickSelectScene:sender];
        }
        
    }

}

@end
