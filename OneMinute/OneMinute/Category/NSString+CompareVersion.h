//
//  NSString+CompareVersion.h
//  TestUpdate
//
//  Created by 陈立勇 on 2017/11/14.
//  Copyright © 2017年 t. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CompareVersion)

-(NSComparisonResult)compareToVersion:(NSString *)version;

-(BOOL)isOlderThanVersion:(NSString *)version;
-(BOOL)isNewerThanVersion:(NSString *)version;
-(BOOL)isEqualToVersion:(NSString *)version;
-(BOOL)isEqualOrOlderThanVersion:(NSString *)version;
-(BOOL)isEqualOrNewerThanVersion:(NSString *)version;

- (NSString *)getMainVersionWithIntegerCount:(NSInteger)integerCount;
- (BOOL)needsToUpdateToVersion:(NSString *)newVersion mainVersionIntegerCount:(NSInteger)integerCount;

@end

