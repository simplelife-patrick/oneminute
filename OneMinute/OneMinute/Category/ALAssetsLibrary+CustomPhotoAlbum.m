
//
//  ALAssetsLibrary+CustomPhotoAlbum.m
//  OneMinute
//
//  Created by chenzonghai on 05/08/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface ALAssetsLibrary (Private)

-(void)addAssetURL:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
       failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock;

@end

@implementation ALAssetsLibrary (CustomPhotoAlbum)

- (void)saveVideo:(NSURL *)videoUrl
          toAlbum:(NSString *)albumName
  completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock
     failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {

    [self writeVideoAtPathToSavedPhotosAlbum: videoUrl
                             completionBlock:^(NSURL *assetURL, NSError *error) {

                                 if (completionBlock) completionBlock(assetURL, error);
                                 
                                 if (error != nil)
                                     return;
                                 
                                 [self addAssetURL:assetURL
                                            toAlbum:albumName
                                       failureBlock:failureBlock];
                             }];
}

#pragma mark - Private Method

-(void)addAssetURL:(NSURL *)assetURL toAlbum:(NSString *)albumName failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
    
    __block BOOL albumWasFound = NO;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock;
    enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {

        if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            albumWasFound = YES;
            
            [self assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                      [group addAsset:asset];
            }
            failureBlock:failureBlock];
            return;
        }
        
        if (group == nil && albumWasFound == NO) {

            __weak typeof(self) weakSelf = self;
            
            if (! [self respondsToSelector:@selector(addAssetsGroupAlbumWithName:resultBlock:failureBlock:)])
                NSLog(@"![WARNING][LIB:ALAssetsLibrary+CustomPhotoAlbum]: \
                      |-addAssetsGroupAlbumWithName:resultBlock:failureBlock:| \
                      only available on iOS 5.0 or later. \
                      ASSET cannot be saved to album!");
            
            else [self addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group) {
                                           
               [weakSelf assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                   [group addAsset:asset];
               } failureBlock:failureBlock];
            }
            failureBlock:failureBlock];
            return;
        }
    };
    
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:enumerationBlock failureBlock:failureBlock];
}

@end
