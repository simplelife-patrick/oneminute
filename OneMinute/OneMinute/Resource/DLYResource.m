//
//  DLYResource.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYResource.h"
#import "DLYMiniVlogDraft.h"


@interface DLYResource ()

@end

@implementation DLYResource

-(NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}
- (void) getResoourcePath{
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentPath = [homeDir objectAtIndex:0];
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:DataFolder];
    if ([_fileManager fileExistsAtPath:dataPath]) {
        
        NSString *resourcePath = [dataPath stringByAppendingPathComponent:ResourceFolder];
        if ([_fileManager fileExistsAtPath:resourcePath]) {
           _resourceFolderPath = resourcePath;
        }
    }
}

- (NSURL *) loadResourceWithType:(DLYResourceType)resourceType fileName:(NSString *)fileName{
    [self getResoourcePath];
    
    switch (resourceType) {
        case DLYResourceTypeVideoHeader:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:VideoHeaderFolder];
            break;
        case DLYResourceTypeVideoTailer:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:VideoTailerFolder];
            break;

        case DLYResourceTypeBGM:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:BGMFolder];
            break;

        case DLYResourceTypeSoundEffect:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:SoundEffectFolder];
            break;

        case DLYResourceTypeSampleVideo:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:SoundEffectFolder];
            break;
        default:
            break;
    }
    
    if ([_fileManager fileExistsAtPath:_resourcePath]) {
        
        NSArray *resourcesArray = [_fileManager contentsOfDirectoryAtPath:_resourcePath error:nil];
        
        for (NSString *path in resourcesArray) {
            if([path isEqualToString:fileName]){
                ;
                NSURL *url = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:path ofType:nil]];
                return url;
            }
        }
    }
    return nil;
}
-(NSArray *)loadBDraftParts{
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentPath = [homeDir objectAtIndex:0];
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:DataFolder];
    if ([_fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:DraftFolder];
        if ([_fileManager fileExistsAtPath:draftPath]) {
            NSArray *draftArray = [_fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            NSMutableArray *mArray = [NSMutableArray array];
            for (NSString *path in draftArray) {
                if ([path hasSuffix:@"mp4"]) {
                    NSURL *url = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:path ofType:nil]];
                    [mArray addObject:url];
                }
            }
            return mArray;
        }
    }
    return nil;
}

@end
