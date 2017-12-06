//
//  DLYPreviewView.h
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "DLYImageTarget.h"

@interface DLYPreviewView : GLKView<DLYImageTarget>

@property (strong, nonatomic) CIFilter *filter;
@property (strong, nonatomic) CIContext *coreImageContext;

@end
