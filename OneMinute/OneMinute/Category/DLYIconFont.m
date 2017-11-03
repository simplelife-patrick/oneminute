//
//  DLYIconFont.m
//  TestIconfont
//
//  Created by 陈立勇 on 2017/11/3.
//  Copyright © 2017年 t. All rights reserved.
//

#import "DLYIconFont.h"

@implementation DLYIconFont

+ (NSString*) stringWithIconName:(DLYIFName)iconName {
    
    return [[self iconfontDictionaryList] objectForKey:@(iconName)];
}

+ (NSDictionary*) iconfontDictionaryList {
    return @{
             @(IFSuccessful)            :@"\U0000e66b",
             @(IFPlayVideo)             :@"\U0000e66c",
             @(IFStopVideo)             :@"\U0000e66a",
             @(IFPrimary)               :@"\U0000e67e",
             @(IFSecondary)             :@"\U0000e67d",
             @(IFAdvanced)              :@"\U0000e682",
             @(IFGoNorth)               :@"\U0000e683",
             @(IFMyMaldives)            :@"\U0000e67b",
             @(IFBigMeal)               :@"\U0000e67f",
             @(IFAfternoonTea)          :@"\U0000e678",
             @(IFDelicious)             :@"\U0000e680",
             @(IFColorfulLife)          :@"\U0000e684",
             @(IFSunSetBeach)           :@"\U0000e67c",
             @(IFYoungOuting)           :@"\U0000e679",
             @(IFSpiritTerritory)       :@"\U0000e681",
             @(IFFlashOff)              :@"\U0000e600",
             @(IFToggleLens)            :@"\U0000e668",
             @(IFRecord)                :@"\U0000e664",
             @(IFDeleteAll)             :@"\U0000e669",
             @(IFDetelePart)            :@"\U0000e667",
             @(IFFlashOn)               :@"\U0000e601",
             @(IFFastLens)              :@"\U0000e670",
             @(IFSlowLens)              :@"\U0000e66f",
             @(IFStopToggle)            :@"\U0000e685",
             @(IFShut)                  :@"\U0000e666",
             @(IFShowVideo)             :@"\U0000e63f",
             @(IFSure)                  :@"\U0000e602",
             @(IFBack)                  :@"\U0000e64d",
             @(IFMute)                  :@"\U0000e663",
             };
}

@end
