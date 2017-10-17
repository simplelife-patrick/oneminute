//
//  NSObject+JSONCategories.h
//  ONEPicture
//
//  Created by 两幅画 on 16/8/15.
//  Copyright © 2016年 一幅画. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JSONCategories)


/**
 * 描述：将NSArray或者NSDictionary转化为NSData
 * 参数：
 * 返回值：转化后的NSData
 *
 */
-(NSData*)JSONData;

/**
 * 描述：将NSArray或者NSDictionary转化为NSString
 * 参数：
 * 返回值：转化后的NSString
 *
 */
-(NSString*)JSONString;

@end
