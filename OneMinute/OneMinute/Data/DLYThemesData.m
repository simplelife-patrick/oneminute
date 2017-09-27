//
//  DLYThemesData.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/21.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYThemesData.h"
#import <UIKit/UIKit.h>
#import "UIImage+Extension.h"


@implementation DLYThemesData

+ (DLYThemesData *) sharedInstance
{
    static DLYThemesData *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[DLYThemesData alloc] init];
    });
    
    return singleton;
}

- (instancetype)init
{
    if (self = [super init])
    {
        // Only run once
        
        [self initThemesDataWithHeader];
        [self initThemesDataWithFooter];
    }
    
    return self;
}

- (void)initThemesDataWithFooter {

    self.footImgArr = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //294
        for (int i = 6; i<294; i++)
        {
            @autoreleasepool {
                //1.
//                NSString *imageName = [NSString stringWithFormat:@"2_00%03d", i];
//                UIImage *image = [UIImage imageNamed:imageName];
//                UIImage *newImage = [weakSelf imageWithImageSimple:image scaledToSize:CGSizeMake(600, 600)];
//                [weakSelf.footImgArr addObject:(id)newImage.CGImage];
                //2.
//                NSString *imageName = [NSString stringWithFormat:@"2_00%03d.png", i];
//                UIImage *image = [UIImage imageNamed:imageName];
//                [weakSelf.footImgArr addObject:(id)image.CGImage];
//                NSLog(@"片尾个数：%zd", self.footImgArr.count);
                //3.
                NSString *imageName = [NSString stringWithFormat:@"2_00%03d.png", i];
                UIImage *image = [UIImage imageNamed:imageName];
                UIImage *newImage = [image scaleToSize:CGSizeMake(600, 600)];
                [weakSelf.footImgArr addObject:(id)newImage.CGImage];
            }
        }
    });
}


- (NSMutableArray *)getFootImageArray {
    
    return self.footImgArr;
}

- (NSMutableArray *)getHeadImageArray {
    
    return self.headImgArr;
}

- (void)initThemesDataWithHeader {
    
    self.headImgArr = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //200
        for (int i = 0; i<200; i++)
        {
            @autoreleasepool {
                //1.
//                NSString *imageName = [NSString stringWithFormat:@"Title 02_00%03d", i];
//                UIImage *image = [UIImage imageNamed:imageName];
//                UIImage *newImage = [weakSelf imageWithImageSimple:image scaledToSize:CGSizeMake(600, 600)];
//                [weakSelf.headImgArr addObject:(id)newImage.CGImage];
                //2.
//                NSString *imageName = [NSString stringWithFormat:@"Title_02_00%03d.png", i];
//                UIImage *image = [UIImage imageNamed:imageName];
//                [weakSelf.headImgArr addObject:(id)image.CGImage];
//                NSLog(@"片头个数：%zd", self.headImgArr.count);
                //3.
                NSString *imageName = [NSString stringWithFormat:@"Title_02_00%03d.png", i];
                UIImage *image = [UIImage imageNamed:imageName];
                UIImage *newImage = [image scaleToSize:CGSizeMake(600, 600)];
                [weakSelf.headImgArr addObject:(id)newImage.CGImage];
            }
        }
    });
}

//- (UIImage *)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize {
//    
//    UIGraphicsBeginImageContext(newSize);
//    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
//    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
////    CGImageRelease(image.CGImage);
////    image = nil;
//    return newImage;
//}

@end
