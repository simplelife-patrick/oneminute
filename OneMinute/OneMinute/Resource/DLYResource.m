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
-(NSString *)resourceFolderPath{

    if (!_resourceFolderPath) {
        
        NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        NSString *documentPath = [homeDir objectAtIndex:0];
        
        NSString *dataPath = [documentPath stringByAppendingPathComponent:kDataFolder];
        if ([_fileManager fileExistsAtPath:dataPath]) {
            
            NSString *resourceFolderPath = [dataPath stringByAppendingPathComponent:kResourceFolder];
            if ([_fileManager fileExistsAtPath:resourceFolderPath]) {
                _resourceFolderPath = resourceFolderPath;
            }
        }
    }
    return _resourceFolderPath;
}
- (void) getSubFolderPathWithSubFolderName:(NSString *)subFolderName{
    NSString *subFolderPath = [kPathDocument stringByAppendingPathComponent:subFolderName];
    if ([_fileManager fileExistsAtPath:subFolderPath]) {
        
    }
}

- (NSURL *) loadResourceWithType:(DLYResourceType)resourceType fileName:(NSString *)fileName{
    
    switch (resourceType) {
        case DLYResourceTypeVideoHeader:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:kVideoHeaderFolder];
            break;
        case DLYResourceTypeVideoTailer:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:kVideoTailerFolder];
            break;

        case DLYResourceTypeBGM:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:kBGMFolder];
            break;

        case DLYResourceTypeSoundEffect:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:kSoundEffectFolder];
            break;

        case DLYResourceTypeSampleVideo:
            _resourcePath = [_resourceFolderPath stringByAppendingPathComponent:kSoundEffectFolder];
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
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([_fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
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
- (NSURL *) saveDraftPartWithPartNum:(NSInteger)partNum{
    //获取Data路径
    NSURL *outPutUrl = nil;
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSString *outputPath = [NSString stringWithFormat:@"%@/part%lu%@",draftPath,partNum,@"mp4"];
            outPutUrl = [NSURL fileURLWithPath:outputPath];
        }
    }
    return outPutUrl;
}
- (NSURL *) saveToSandboxWithPath:(NSString *)resourcePath suffixType:(NSString *)suffixName{
    
    CocoaSecurityResult * result = [CocoaSecurity md5:[[NSDate date] description]];
    
    //获取Data路径
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //获取Data 子文件夹下文件夹路径
    NSString *subFolderPath = [dataPath stringByAppendingPathComponent:resourcePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:subFolderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:subFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@%@",subFolderPath,result.hex,suffixName];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    return outPutUrl;
}
- (NSURL *) saveToSandboxWithFolderType:(NSSearchPathDirectory)sandboxFolderType subfolderName:(NSString *)subfolderName suffixType:(NSString *)suffixName{
    
    CocoaSecurityResult * result = [CocoaSecurity md5:[[NSDate date] description]];
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(sandboxFolderType, NSUserDomainMask,YES);
    NSString *documentsDir = [homeDir objectAtIndex:0];
    NSString *filePath = [documentsDir stringByAppendingPathComponent:subfolderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@%@",filePath,result.hex,suffixName];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    return outPutUrl;
}
- (void) removePartWithPartNum:(NSInteger)partNum{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    BOOL isDelete =  [fileManager removeItemAtPath:dataPath error:nil];
    DLYLog(@"%@",isDelete ? @"成功第 %lu 个片段":@"删除第 %lu 个片段失败",partNum);
}
- (void) removeCurrentAllPart{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *draftFolderPath = [kPathDocument stringByAppendingPathComponent:kDraftFolder];
    BOOL isDelete = [fileManager removeItemAtPath:draftFolderPath error:nil];
    DLYLog(@"%@",isDelete ? @"成功删除所有片段":@"删除所有片段失败");
}
@end
