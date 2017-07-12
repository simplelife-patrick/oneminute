//
//  DLYResource.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYResource.h"

@interface DLYResource ()

@property (nonatomic, strong) NSFileManager                *fileManager;

@end

@implementation DLYResource

-(NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}
- (NSString *) getDataPath{
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentPath = [homeDir objectAtIndex:0];
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"Data"];
    if ([_fileManager fileExistsAtPath:dataPath]) {
        return dataPath;
    }
    return nil;
}
- (void) loadBVideoHeaderWithFileName:(NSString *)fileName{
    
    NSString *dataPath = [self getDataPath];
    NSString *resourcePath = [dataPath stringByAppendingPathComponent:@"Resource"];
    
    if ([_fileManager fileExistsAtPath:dataPath] && [_fileManager fileExistsAtPath:resourcePath]) {
        
        NSArray *resourcesArray = [_fileManager contentsOfDirectoryAtPath:resourcePath error:nil];
    }
}

- (void) loadBVideoTailerWithFileName:(NSString *)fileName{
    
    NSString *dataPath = [self getDataPath];
    NSString *ResourcePath = [dataPath stringByAppendingPathComponent:@"Resource"];
    
    if ([_fileManager fileExistsAtPath:ResourcePath]) {
        
    }
}

- (void) loadBVideoBGMWithFileName:(NSString *)fileName{
    
    NSString *dataPath = [self getDataPath];
    NSString *ResourcePath = [dataPath stringByAppendingPathComponent:@"Resource"];
    
    if ([_fileManager fileExistsAtPath:ResourcePath]) {
        
    }
}

- (void) loadTemplateSampleWithFileName:(NSString *)fileName{
    
    NSString *dataPath = [self getDataPath];
    NSString *samplesPath = [dataPath stringByAppendingPathComponent:@"Samples"];
    
    if ([_fileManager fileExistsAtPath:samplesPath]) {
        
    }
}

- (void) loadBDraftParts{
    
}

@end
