
//
//  DLYPreviewView.m
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYPreviewView.h"
#import "DLYContextManager.h"
#import "DLYFunctions.h"

@interface DLYPreviewView ()

@property (nonatomic) CGRect drawableBounds;

@end

@implementation DLYPreviewView

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
    self = [super initWithFrame:frame context:context];
    if (self) {
        self.enableSetNeedsDisplay = NO;
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
//        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.frame = frame;
        
        [self bindDrawable];
        _drawableBounds = self.bounds;
        _drawableBounds.size.width = self.drawableWidth;
        _drawableBounds.size.height = self.drawableHeight;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(filterChanged:)
                                                     name:DLYFilterSelectionChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)filterChanged:(NSNotification *)notification {
    self.filter = notification.object;
}

- (void)setImage:(CIImage *)sourceImage {
    
    [self bindDrawable];
    
    [self.filter setValue:sourceImage forKey:kCIInputImageKey];
    CIImage *filteredImage = self.filter.outputImage;
    if (!filteredImage) {
        filteredImage = sourceImage;
    }
    if (filteredImage) {
        
        CGRect cropRect = DLYCenterCropImageRect(sourceImage.extent, self.drawableBounds);
        
        [self.coreImageContext drawImage:filteredImage
                                  inRect:self.drawableBounds
                                fromRect:cropRect];
    }
    
    [self display];
    [self.filter setValue:nil forKey:kCIInputImageKey];
}

@end
