//
//  DLYPhotoFilters.h
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYPhotoFilters : NSObject
@property (nonatomic,assign)BOOL filterEnabled;
@property (nonatomic,assign)NSInteger currentFilterIndex;

- (NSArray *)filterNames;
- (NSArray *)filterDisplayNames;
- (CIFilter *)filterForDisplayName:(NSString *)displayName;
- (CIFilter *)defaultFilter;
- (CIFilter *)currentFilter;
- (NSString *)currentDisplayFilterName;
+ (BOOL)filterEnabled;
+ (instancetype)sharedInstance;
@end
