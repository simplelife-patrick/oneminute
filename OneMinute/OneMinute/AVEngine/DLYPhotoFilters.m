
//
//  DLYPhotoFilters.m
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYPhotoFilters.h"
#import "NSString+DLYAdditions.h"

@interface DLYPhotoFilters()
{
    
}
@property (nonatomic,strong)NSArray* filterNames;
@property (nonatomic,strong)CIFilter* currentFilter;
@end
@implementation DLYPhotoFilters

static id _instance;
//重写allocWithZone:方法，在这里创建唯一的实例(注意线程安全)
+(id)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _instance = [super allocWithZone:zone];
        
    });
    
    return _instance;
}

+ (instancetype)sharedInstance{
    @synchronized(self){
        if(_instance == nil){
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (NSArray *)filterNames {
    
    return @[@"CIPhotoEffectChrome",
             @"CIPhotoEffectTransfer",
             @"CIPhotoEffectInstant",
             @"CIPhotoEffectMono",
             ];
}

- (NSArray *)filterDisplayNames {
    
//    NSMutableArray *displayNames = [NSMutableArray array];
//    
//    for (NSString *filterName in [self filterNames]) {
//        [displayNames addObject:[filterName stringByMatchingRegex:@"CIPhotoEffect(.*)" capture:1]];
//    }
    
    return @[@"01  盛夏时光",
             @"02  春暖花开",
             @"03  冬季飞雪",
             @"04  灰度世界",
             ];;
}

- (CIFilter *)defaultFilter {
    return [CIFilter filterWithName:[[self filterNames] objectAtIndex:0]];
}
-(CIFilter *)currentFilter{
    if (self.filterEnabled) {
        return [CIFilter filterWithName:[[self filterNames] objectAtIndex:_currentFilterIndex]];
    }else{
        return nil;
    }
    
}
- (CIFilter *)filterForDisplayName:(NSString *)displayName {
    for (NSString *name in [self filterNames]) {
        if ([name containsString:displayName]) {
            return [CIFilter filterWithName:name];
        }
    }
    return nil;
}
-(void)setCurrentFilterIndex:(NSInteger)currentFilterIndex{
    _currentFilterIndex = currentFilterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:DLYFilterSelectionChangedNotification object:[self currentFilter]];

}
-(void)setFilterEnabled:(BOOL)filterEnabled{
    _filterEnabled = filterEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:DLYFilterSelectionChangedNotification object:[self currentFilter]];
}
- (NSString *)currentDisplayFilterName{
    if (self.filterEnabled) {
        return [[self filterDisplayNames] objectAtIndex:_currentFilterIndex];
    }else{
        return @"";
    }
}
@end
