//
//  DLYTitleView.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/5.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYTitleView.h"

@interface DLYTitleView ()

@property (nonatomic, strong) UILabel *partLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *typeLabvel;
@property (nonatomic, strong) UIView *leftLine;
@property (nonatomic, strong) UIView *rightLine;

@end

@implementation DLYTitleView

- (instancetype)initWithPartTitle:(NSString *)partTitle timeTitle:(NSString *)timeTitle typeTitle:(NSString *)typeTitle {
    
    self = [super init];
    if (self) {
        self.backgroundColor = RGBA(0, 0, 0, 0.5);
        self.layer.cornerRadius = 4;
        self.clipsToBounds = YES;
        [self createViewWithPartTitle:partTitle timeTitle:timeTitle typeTitle:typeTitle];
    }
    return self;
}


- (void)createViewWithPartTitle:(NSString *)partTitle timeTitle:(NSString *)timeTitle typeTitle:(NSString *)typeTitle {
    
    self.partLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 40, 20)];
    self.partLabel.font = FONT_SYSTEM(14);
    self.partLabel.textColor = RGB(255, 255, 255);
    self.partLabel.text = partTitle;
    self.partLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.partLabel];
    
    self.leftLine = [[UIView alloc] initWithFrame:CGRectMake(self.partLabel.right + 7, 6, 1, 18)];
    self.leftLine.backgroundColor = RGB(255, 255, 255);
    [self addSubview:self.leftLine];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.leftLine.right + 7, 5, 40, 20)];
    self.timeLabel.font = FONT_SYSTEM(14);
    self.timeLabel.textColor = RGB(255, 255, 255);
    self.timeLabel.text = timeTitle;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.timeLabel];
    
    self.rightLine = [[UIView alloc] initWithFrame:CGRectMake(self.timeLabel.right + 7, 6, 1, 18)];
    self.rightLine.backgroundColor = RGB(255, 255, 255);
    [self addSubview:self.rightLine];
    
    self.typeLabvel = [[UILabel alloc] initWithFrame:CGRectMake(self.rightLine.right + 7, 5, 45, 20)];
    self.typeLabvel.font = FONT_SYSTEM(14);
    self.typeLabvel.textColor = RGB(255, 255, 255);
    self.typeLabvel.text = typeTitle;
    self.typeLabvel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.typeLabvel];
    
}

@end
