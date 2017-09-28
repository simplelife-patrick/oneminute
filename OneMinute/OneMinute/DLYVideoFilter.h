//
//  DLYVideoFilter.h
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/28.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import <GPUImage/GPUImage.h>
@class GPUImagePicture;

@interface DLYVideoFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}
@end
