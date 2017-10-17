//
//  DLYVideoFilter.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/28.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYVideoFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@implementation DLYVideoFilter
- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"videoFilter01.png"];
#else
    NSImage *image = [NSImage imageNamed:@"videoFilter01.png"];
#endif
    
    NSAssert(image, @"To use GPUImageAmatorkaFilter you need to add videoFilter01.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end


