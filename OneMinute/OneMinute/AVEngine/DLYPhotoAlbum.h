//
//  DLYPhotoAlbum.h
//  OneMinute
//
//  Created by chenzonghai on 30/10/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuccessBlock)(void);
typedef void(^FailureBlock)(NSError *error);

@interface DLYPhotoAlbum : NSObject

- (void) saveVideoToAlbumWithUrl:(NSURL *)videoUrl allbumName:(NSString *)albumName successed:(SuccessBlock)success failured:(FailureBlock)failured;

@end
