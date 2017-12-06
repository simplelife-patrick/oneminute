//
//  DLYPhotoFilters.h
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYPhotoFilters : NSObject

+ (NSArray *)filterNames;
+ (NSArray *)filterDisplayNames;
+ (CIFilter *)filterForDisplayName:(NSString *)displayName;
+ (CIFilter *)defaultFilter;

@end
