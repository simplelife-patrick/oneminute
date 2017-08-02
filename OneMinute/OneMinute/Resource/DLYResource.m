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

-(NSURL *)getTemplateSampleWithName:(NSString *)sampleName{
    NSString *path = [[NSBundle mainBundle] pathForResource:sampleName ofType:nil];
    NSURL *sampleUrl = [NSURL fileURLWithPath:path];
    return sampleUrl;
}

- (NSString *) getSubFolderPathWithFolderName:(NSString *)folderName{
    
    //拼接Data文件夹路径
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    //判断最后Data路径是否存在
    if ([self.fileManager fileExistsAtPath:dataPath]) {
        //拼接子文件夹路径
        NSString *folderPath = [dataPath stringByAppendingPathComponent:folderName];
        //判断子文件夹是否存在
        if ([self.fileManager fileExistsAtPath:folderPath]) {
            //存在就把子文件夹返回
            return folderPath;
        }
    }
    return nil;
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
    if ([self.fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([self.fileManager fileExistsAtPath:draftPath]) {
            NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            NSMutableArray *mArray = [NSMutableArray array];
            for (NSString *path in draftArray) {
                if ([path hasSuffix:@"mp4"]) {
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    [mArray addObject:url];
                }
            }
            return mArray;
        }
    }
    return nil;
}
- (NSURL *) saveDraftPartWithPartNum:(NSInteger)partNum{
    
    NSURL *outPutUrl = nil;
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSString *outputPath = [NSString stringWithFormat:@"%@/part%lu%@",draftPath,partNum,@".mp4"];
            outPutUrl = [NSURL fileURLWithPath:outputPath];
        }
    }
    return outPutUrl;
}
- (NSURL *) saveProductToSandbox{
    
    NSURL *outPutUrl = nil;
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
            
            CocoaSecurityResult * result = [CocoaSecurity md5:[[NSDate date] description]];
            
            NSString *outputPath = [NSString stringWithFormat:@"%@/%@%@",productPath,result.hex,@".mp4"];
            _currentProductPath = outputPath;
            NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
            return outPutUrl;
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
- (NSURL *) saveToSandboxFolderType:(NSSearchPathDirectory)sandboxFolderType subfolderName:(NSString *)subfolderName suffixType:(NSString *)suffixName{
    
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
    
    NSString *draftPath = [self getSubFolderPathWithFolderName:kDraftFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSString *targetPath = [draftPath stringByAppendingFormat:@"/part%lu.mp4",partNum];
        
        BOOL isDelete = [fileManager removeItemAtPath:targetPath error:nil];
        DLYLog(@"%@",isDelete ? @"成功删除第 %lu 个片段":@"删除第 %lu 个片段失败",partNum + 1);
    }
}
- (void) removeCurrentAllPart{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *draftPath = [self getSubFolderPathWithFolderName:kDraftFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:draftPath error:nil];
        
        for (NSString *path in draftArray) {
            if ([path hasSuffix:@"mp4"]) {
                NSString *targetPath = [draftPath stringByAppendingFormat:@"/%@",path];
                BOOL isDelete = [fileManager removeItemAtPath:targetPath error:nil];
                DLYLog(@"%@",isDelete ? @"删除片段成功":@"删除片段失败");
            }
        }
        DLYLog(@"成功删除所有草稿片段");
    }
}
- (NSURL *) getPartUrlWithPartNum:(NSInteger)partNum{
    
    NSString *draftPath = [self getSubFolderPathWithFolderName:kDraftFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSString *targetPath = [draftPath stringByAppendingFormat:@"/part%lu.mp4",partNum];
        NSURL *targetUrl = [NSURL fileURLWithPath:targetPath];
        return targetUrl;
    }
    return nil;
}

- (NSURL *) getProductWithProductName:(NSString *)productName{
    
    NSString *productPath = [self getSubFolderPathWithFolderName:kProductFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        NSString *targetPath = [productPath stringByAppendingFormat:@"/%@.mp4",productName];
        NSURL *targetUrl = [NSURL URLWithString:targetPath];
        return targetUrl;
    }
    return nil;
}
@end
