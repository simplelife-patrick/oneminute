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
        if ([self.fileManager fileExistsAtPath:dataPath]) {
            
            NSString *resourceFolderPath = [dataPath stringByAppendingPathComponent:kResourceFolder];
            if ([self.fileManager fileExistsAtPath:resourceFolderPath]) {
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
            _resourcePath = [self.resourceFolderPath stringByAppendingPathComponent:kVideoHeaderFolder];
            break;
        case DLYResourceTypeVideoTailer:
            _resourcePath = [self.resourceFolderPath stringByAppendingPathComponent:kVideoTailerFolder];
            break;

        case DLYResourceTypeBGM:
            _resourcePath = [self.resourceFolderPath stringByAppendingPathComponent:kBGMFolder];
            break;

        case DLYResourceTypeSoundEffect:
            _resourcePath = [self.resourceFolderPath stringByAppendingPathComponent:kSoundEffectFolder];
            break;

        case DLYResourceTypeSampleVideo:
            _resourcePath = [self.resourceFolderPath stringByAppendingPathComponent:kSoundEffectFolder];
            break;
        default:
            break;
    }
    
    if ([self.fileManager fileExistsAtPath:self.resourcePath]) {
        
        NSArray *resourcesArray = [self.fileManager contentsOfDirectoryAtPath:self.resourcePath error:nil];
        
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
-(NSArray *)loadDraftPartsFromTemp{
    
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kTempFolder];
    if ([self.fileManager fileExistsAtPath:tempPath]) {
        
        NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:tempPath error:nil];
        NSMutableArray *mArray = [NSMutableArray array];
        for (NSString *path in draftArray) {
            if ([path hasSuffix:@"mp4"]) {
                NSString *allPath = [tempPath stringByAppendingFormat:@"/%@",path];
                NSURL *url= [NSURL fileURLWithPath:allPath];
                [mArray addObject:url];
            }
        }
        return mArray;
    }
    return nil;
}
- (NSArray *) loadDraftPartsFromDocument{
    
    NSMutableArray *videoArray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            for (NSInteger i = 0; i < [draftArray count]; i++) {
                NSString *path = draftArray[i];
                if ([path hasSuffix:@"mp4"]) {
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    [videoArray addObject:url];
                }
            }
            return videoArray;
        }
    }
    return nil;
}

- (NSURL *) saveProductToSandbox{
    
    NSURL *outPutUrl = nil;
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
            
            NSString *UUIDString = [self stringWithUUID];
            
            NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",productPath,UUIDString];
            _currentProductPath = outputPath;
            NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
            return outPutUrl;
        }
    }
    return outPutUrl;
}
- (NSURL *) saveToSandboxWithPath:(NSString *)resourcePath suffixType:(NSString *)suffixName{
    
//    CocoaSecurityResult * result = [CocoaSecurity md5:[[NSDate date] description]];
    NSString *UUIDString = [self stringWithUUID];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *subFolderPath = [dataPath stringByAppendingPathComponent:resourcePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:subFolderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:subFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@%@",subFolderPath,UUIDString,suffixName];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    return outPutUrl;
}
- (NSURL *) saveToSandboxFolderType:(NSSearchPathDirectory)sandboxFolderType subfolderName:(NSString *)subfolderName suffixType:(NSString *)suffixName{
    
    NSString *UUIDString = [self stringWithUUID];
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(sandboxFolderType, NSUserDomainMask,YES);
    NSString *documentsDir = [homeDir objectAtIndex:0];
    NSString *filePath = [documentsDir stringByAppendingPathComponent:subfolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@%@",filePath,UUIDString,suffixName];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    return outPutUrl;
}
- (void) removePartWithPartNumFormTemp:(NSInteger)partNum{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kTempFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        
        NSString *targetPath = [tempPath stringByAppendingFormat:@"/part%lu.mp4",partNum];
        
        [fileManager removeItemAtPath:targetPath error:nil];
    }
}
#pragma mark - 删除文件 -
- (void) removePartWithPartNumFromDocument:(NSInteger)partNum
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *draftPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kDraftFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSString *targetPath = [draftPath stringByAppendingFormat:@"/part%lu.mp4",partNum];
        
        [fileManager removeItemAtPath:targetPath error:nil];
    }
}
- (void) removeCurrentAllPartFromTemp
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kTempFolder];

    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        
        NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:tempPath error:nil];
        BOOL isSuccess = NO;
        if ([draftArray count] != 0) {
            for (NSString *path in draftArray) {
                if ([path hasSuffix:@"mp4"]) {
                    NSString *targetPath = [tempPath stringByAppendingFormat:@"/%@",path];
                    isSuccess = [fileManager removeItemAtPath:targetPath error:nil];
                }
            }
            DLYLog(@"%@",isSuccess?@"成功删除Cache中全部草稿片段":@"删除Cache中全部草稿片段失败");
        }else{
            DLYLog(@"现在Cache中无视频片段");
        }
    }
}
- (void) removeProductFromDocument
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:productPath error:nil];
        BOOL isSuccess = NO;
        
        if ([draftArray count] != 0) {
            for (NSString *path in draftArray) {
                if ([path hasSuffix:@"mp4"]) {
                    NSString *targetPath = [productPath stringByAppendingFormat:@"/%@",path];
                    isSuccess = [fileManager removeItemAtPath:targetPath error:nil];
                }
            }
            DLYLog(@"%@",isSuccess?@"成功删除Document中的成片视频":@"删除Document成片视频失败");
        }else{
            DLYLog(@"Document中无成片视频");
        }
    }

}
- (void) removeCurrentAllPartFromDocument{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *draftPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kDraftFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSArray *draftArray = [self.fileManager contentsOfDirectoryAtPath:draftPath error:nil];
        BOOL isSuccess = NO;
        
        if ([draftArray count] != 0) {
            for (NSString *path in draftArray) {
                if ([path hasSuffix:@"mp4"]) {
                    NSString *targetPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    isSuccess = [fileManager removeItemAtPath:targetPath error:nil];
                }
            }
            DLYLog(@"%@",isSuccess?@"成功删除Document全部草稿片段":@"删除Document全部草稿片段失败");
        }else{
            DLYLog(@"现在Document中无视频片段");
        }
    }
}

- (NSString *) saveDraftPartWithPartNum:(NSInteger)partNum{
    
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kTempFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        
        NSString *outputPath = [NSString stringWithFormat:@"%@/part%lu%@",tempPath,(long)partNum,@".mp4"];
        return outputPath;
    }
    return nil;
}
- (NSURL *) getPartUrlWithPartNum:(NSInteger)partNum
{
    NSString *draftPath = [NSString stringWithFormat:@"%@/%@/%@",kPathDocument,kDataFolder,kDraftFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
        
        NSString *targetPath = [draftPath stringByAppendingFormat:@"/part%lu.mp4",partNum];
        NSURL *targetUrl = [NSURL fileURLWithPath:targetPath];
        return targetUrl;
    }
    return nil;
}

- (NSURL *) getProductWithProductName:(NSString *)productName
{
    NSString *productPath = [self getSubFolderPathWithFolderName:kProductFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        NSString *targetPath = [productPath stringByAppendingFormat:@"/%@.mp4",productName];
        NSURL *targetUrl = [NSURL URLWithString:targetPath];
        return targetUrl;
    }
    return nil;
}
- (NSString *) stringWithUUID {
    
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    return uuidString;
}
@end
