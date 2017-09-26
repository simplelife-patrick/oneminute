//
//  DLYThemesData.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/21.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYThemesData : NSObject

+ (DLYThemesData *) sharedInstance;

@property (nonatomic, strong) NSMutableArray *headImgArr;
@property (nonatomic, strong) NSMutableArray *footImgArr;

- (NSMutableArray *)getHeadImageArray;
- (NSMutableArray *)getFootImageArray;


@end
