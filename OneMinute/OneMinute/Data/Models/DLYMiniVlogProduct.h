//
//  DLYMiniVlogProduct.h
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogTemplate.h"

@interface DLYMiniVlogProduct : DLYModule

/**
 MiniVlog成片编号
 */
@property (nonatomic, strong) NSString               *productId;

/**
 在sandbox中的URL
 */
@property (nonatomic, strong) NSURL                  *Url;

/**
 模板
 */
@property (nonatomic, strong) DLYMiniVlogTemplate    *templateName;


@end
