
//
//  DLYPhotoFilters.m
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYPhotoFilters.h"
#import "NSString+DLYAdditions.h"

@implementation DLYPhotoFilters

+ (NSArray *)filterNames {
    
    return @[@"CIPhotoEffectChrome",
             @"CIPhotoEffectFade",
             @"CIPhotoEffectInstant",
             @"CIPhotoEffectMono",
             @"CIPhotoEffectNoir",
             @"CIPhotoEffectProcess",
             @"CIPhotoEffectTonal",
             @"CIPhotoEffectTransfer"];
}

+ (NSArray *)filterDisplayNames {
    
    NSMutableArray *displayNames = [NSMutableArray array];
    
    for (NSString *filterName in [self filterNames]) {
        [displayNames addObject:[filterName stringByMatchingRegex:@"CIPhotoEffect(.*)" capture:1]];
    }
    
    return displayNames;
}

+ (CIFilter *)defaultFilter {
    return [CIFilter filterWithName:[[self filterNames] objectAtIndex:2]];
}

+ (CIFilter *)filterForDisplayName:(NSString *)displayName {
    for (NSString *name in [self filterNames]) {
        if ([name containsString:displayName]) {
            return [CIFilter filterWithName:name];
        }
    }
    return nil;
}

@end
