//
//  ChooseFilterTableViewCell.m
//  OneMinute
//
//  Created by APPLE on 2017/12/8.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYChooseFilterTableViewCell.h"

@interface DLYChooseFilterTableViewCell(){
    
}
@property (nonatomic,strong)UILabel *titleLabel;
@end
@implementation DLYChooseFilterTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _titleLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = 1;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_titleLabel];
    }
    return  self;
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

    }
    return self;
}
-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text=title;

}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];
    if (selected) {
        _titleLabel.textColor = [UIColor colorWithHex:0xffffff];
    }else{
        _titleLabel.textColor = [UIColor colorWithHex:0x999999];

    }

    // Configure the view for the selected state
}

@end
