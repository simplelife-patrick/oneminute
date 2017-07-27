//
//  DLYVideoTransition.h
//  OneMinute
//
//  Created by chenzonghai on 14/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,DLYVideoTransitionType) {
    DLYVideoTransitionTypeNone = 0,
    DLYVideoTransitionTypeDissolve,
    DLYVideoTransitionTypePush,
    DLYVideoTransitionTypeWipe,
    DLYVideoTransitionTypeClockwiseRotate,
    DLYVideoTransitionTypeZoom
};

typedef NS_ENUM(NSInteger,DLYPushTransitionDirection) {
    DLYPushTransitionDirectionLeftToRight = 0,
    DLYPushTransitionDirectionRightToLeft,
    DLYPushTransitionDirectionTopToButton,
    DLYPushTransitionDirectionBottomToTop,
    DLYPushTransitionDirectionInvalid = INT_MAX
};

@interface DLYVideoTransition : NSObject

+ (id)videoTransition;

@property (nonatomic) DLYVideoTransitionType type;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic) CMTime duration;
@property (nonatomic) DLYPushTransitionDirection direction;


+ (id)disolveTransitionWithDuration:(CMTime)duration;
+ (id)pushTransitionWithDuration:(CMTime)duration direction:(DLYPushTransitionDirection)direction;

@end
