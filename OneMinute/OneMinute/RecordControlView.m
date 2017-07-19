//
//  RecordControlView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/19.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "RecordControlView.h"

@interface RecordControlView (){
    
    //记录白色闪动条的透明度
    NSInteger prepareAlpha;

}

@end

@implementation RecordControlView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self createUI];
    }
    return self;
}

- (void)createUI {
    
    self.backgroundColor = RGBA(0, 0, 0, 0.7);
    //拍摄按钮
    self.recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(43 * SCALE_WIDTH, 0, 60*SCALE_WIDTH, 60 * SCALE_WIDTH)];
    self.recordBtn.centerY = self.centerY;
    [self.recordBtn setImage:[UIImage imageWithIcon:@"\U0000e664" inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.recordBtn.backgroundColor = RGB(255, 0, 0);
    self.recordBtn.layer.cornerRadius = 30 * SCALE_WIDTH;
    self.recordBtn.clipsToBounds = YES;
    [self.recordBtn addTarget:self action:@selector(onTouchRecordBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.recordBtn];
    
    //片段view
    self.vedioEpisode = [[UIView alloc]initWithFrame:CGRectMake(self.recordBtn.right, 15 * SCALE_HEIGHT, 53, SCREEN_HEIGHT - 30  * SCALE_HEIGHT)];
    [self addSubview:self.vedioEpisode];
    self.backScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, 53, self.vedioEpisode.height)];
    self.backScrollView.showsVerticalScrollIndicator = NO;
    self.backScrollView.showsHorizontalScrollIndicator = NO;
    self.backScrollView.bounces = NO;
    [self.vedioEpisode addSubview:self.backScrollView];
    float episodeHeight = (self.vedioEpisode.height - 10)/6;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * self.partModelArray.count + (self.partModelArray.count - 1) * 2);
    self.prepareShootTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(prepareShootAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_prepareShootTimer forMode:NSRunLoopCommonModes];
    [_prepareShootTimer setFireDate:[NSDate distantFuture]];
    
    //右侧编辑页面
    self.playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.recordBtn.x + self.recordBtn.width, SCREEN_HEIGHT)];
    self.playView.hidden = YES;
    [self addSubview:self.playView];
    //右侧：播放某个片段的button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60 * SCALE_WIDTH, (SCREEN_HEIGHT - 152)/2, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.playButton addTarget:self action:@selector(onTouchPlayPartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:15 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.playButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.playButton.layer.borderWidth = 1;
    [self.playView addSubview:self.playButton];
    //右侧：删除某个片段的button
    self.deletePartButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60* SCALE_WIDTH, self.playButton.bottom + 32, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.deletePartButton addTarget:self action:@selector(onTouchDeletePartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.deletePartButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.deletePartButton.layer.borderWidth = 1;
    [self.playView addSubview:self.deletePartButton];
    
    [self createPartView];
    
}

//需要重写一个相似的 只改变颜色,透明度等.显隐
- (void)createPartView {
    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HEIGHT - 30  * SCALE_HEIGHT - 10)/6;
    if(SCREEN_HEIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - 10)/6;
    }
    
    for(int i = 1; i <= self.partModelArray.count; i ++)
    {
        DLYMiniVlogPart *part = self.partModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(43, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        
        UIEdgeInsets edgeInsets = {0, -43, 0, -5};
        [button setHitEdgeInsets:edgeInsets];
        //辨别改变段是否已经拍摄
        if([part.shootStatus isEqualToString:@"1"])
        {
            button.backgroundColor = RGB(255, 0, 0);
            //显示标注
            if(part.recordType == DLYMiniVlogRecordTypeNormal)
            {
                UILabel * timeLabel = [[UILabel alloc] init];
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                timeLabel.text = part.duration;
                [timeLabel sizeToFit];
                timeLabel.frame = CGRectMake(button.left - 4 - timeLabel.width, 0, timeLabel.width, timeLabel.height);
                timeLabel.centerY = button.centerY;
                [self.backScrollView addSubview:timeLabel];
                
            }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
            {//慢动作
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                timeLabel.text = part.duration;
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"慢镜";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }else
            {//延时
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                timeLabel.text = part.duration;
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"延时";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }
        }else
        {
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            // 辨别该片段是否是默认准备拍摄片段
            if([part.prepareShoot isEqualToString:@"1"]){
                //光标
                self.prepareView = [[UIView alloc]initWithFrame:CGRectMake(button.x, button.y, 10, 2)];
                self.prepareView.backgroundColor = [UIColor whiteColor];
                [self.backScrollView addSubview:self.prepareView];
                prepareAlpha = 1;
                [_prepareShootTimer setFireDate:[NSDate distantPast]];
                //判断拍摄状态
                //正常状态
                if(part.recordType == DLYMiniVlogRecordTypeNormal)
                {
                    UILabel * timeLabel = [[UILabel alloc] init];
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = part.duration;
                    [timeLabel sizeToFit];
                    timeLabel.frame = CGRectMake(button.left - 4 - timeLabel.width, 0, timeLabel.width, timeLabel.height);
                    timeLabel.centerY = button.centerY;
                    [self.backScrollView addSubview:timeLabel];
                    
                }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
                {//慢进
                    UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                    itemView.centerY = button.centerY;
                    [self.backScrollView addSubview:itemView];
                    
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = part.duration;
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"慢镜";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }else
                {//延时
                    UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                    itemView.centerY = button.centerY;
                    [self.backScrollView addSubview:itemView];
                    
                    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = part.duration;
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"延时";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }
            }
        }
        
        
        button.tag = 10000 + i;
        [button addTarget:self action:@selector(onTouchvedioEpisode:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
}

//显示光标？！
- (void)prepareShootAction {
    
    [UIView animateWithDuration:0.1f animations:^{
        if(prepareAlpha == 1)
        {
            self.prepareView.alpha = 0;
        }else
        {
            self.prepareView.alpha = 1;
        }
    } completion:^(BOOL finished) {
        if(prepareAlpha == 1)
        {
            prepareAlpha = 0;
        }else
        {
            prepareAlpha = 1;
        }
        
    }];
    
}
#pragma mark ==== 点击方法

- (void)onTouchvedioEpisode:(UIButton *)sender {
    
    
    if ([self.delegate respondsToSelector:@selector(vedioEpisodeClick:)]) {
        [self.delegate vedioEpisodeClick:sender];
    }
    
}

- (void)onTouchRecordBtn:(UIButton *)sender {

    if ([self.delegate respondsToSelector:@selector(startRecordBtn:)]) {
        [self.delegate startRecordBtn:sender];
    }
}

//播放某个片段
- (void)onTouchPlayPartVideo:(UIButton *)sender{
    
    if ([self.delegate respondsToSelector:@selector(onClickPlayPartVideo:)]) {
        [self.delegate onClickPlayPartVideo:sender];
    }
}
//删除某个片段
- (void)onTouchDeletePartVideo:(UIButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(onClickDeletePartVideo:)]) {
        [self.delegate onClickDeletePartVideo:sender];
    }
}

@end
