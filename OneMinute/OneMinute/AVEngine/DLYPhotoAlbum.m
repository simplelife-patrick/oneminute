//
//  DLYPhotoAlbum.m
//  OneMinute
//
//  Created by chenzonghai on 30/10/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYPhotoAlbum.h"
#import <Photos/Photos.h>

@implementation DLYPhotoAlbum


- (BOOL)isExistFolder:(NSString *)albumName {

    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    __block BOOL isExisted = NO;
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;

        if ([assetCollection.localizedTitle isEqualToString:albumName])  {
            isExisted = YES;
        }
    }];
    return isExisted;
}

- (void) saveVideoToAlbumWithUrl:(NSURL *)videoUrl allbumName:(NSString *)albumName successed:(SuccessBlock)success failured:(FailureBlock)failured
{
    if (![self isExistFolder:albumName]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                DLYLog(@"成功创建相册文件夹!");
            } else {
                DLYLog(@"创建相册文件夹失败:%@", error);
            }
        }];
    }
    
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;

        if ([assetCollection.localizedTitle isEqualToString:albumName])  {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                
                PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoUrl];
                PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
                [collectonRequest addAssets:@[placeHolder]];
                
            } completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    DLYLog(@"视频成功保存!");

                } else {
                    DLYLog(@"保存视频失败:%@", error);
                }
            }];
        }
    }];
}

@end
