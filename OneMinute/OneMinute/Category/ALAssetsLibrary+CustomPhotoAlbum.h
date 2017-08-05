//
//  ALAssetsLibrary+CustomPhotoAlbum.h
//  OneMinute
//
//  Created by chenzonghai on 05/08/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary (CustomPhotoAlbum)

/**
 保存视频到相册到自定义文件夹

 @param videoUrl 视频路径
 @param albumName 自定义相册名称
 @param completionBlock 成功回调
 @param failureBlock 失败回调
 */
-(void)saveVideo:(NSURL *)videoUrl
         toAlbum:(NSString *)albumName
 completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock
    failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock;

@end
