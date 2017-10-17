//
//  UIImage+Extension.h
//  OneMinute
//
//  Created by chenzonghai on 30/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (UIImage *)getImageStream:(CVImageBufferRef)imageBuffer;
+ (UIImage *)getSubImage:(CGRect)rect inImage:(UIImage*)image;

- (UIImage *)originalImage;
- (UIImage *)scaleToSize:(CGSize)size;

@end
