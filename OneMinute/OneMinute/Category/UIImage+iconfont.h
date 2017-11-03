//
//  UIImage+iconfont.h
//  test
//
//  Created by 两幅画 on 2017/6/26.
//  Copyright © 2017年 两幅画. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLYIconFont.h"

@interface UIImage (iconfont)

+ (UIImage*)imageWithIcon:(NSString*)iconCode inFont:(NSString*)fontName size:(NSUInteger)size color:(UIColor*)color;
+ (UIImage*)imageWithIconName:(DLYIFName)iconName inFont:(NSString*)fontName size:(NSUInteger)size color:(UIColor*)color;
@end
