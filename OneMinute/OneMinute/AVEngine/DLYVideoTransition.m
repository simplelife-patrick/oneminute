
//
//  DLYVideoTransition.m
//  OneMinute
//
//  Created by chenzonghai on 14/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYVideoTransition.h"

@implementation DLYVideoTransition

+ (id)videoTransition {
    return [[[self class] alloc] init];
}

+ (id)disolveTransitionWithDuration:(CMTime)duration {
    DLYVideoTransition *transition = [self videoTransition];
    transition.type = DLYVideoTransitionTypeDissolve;
    transition.duration = duration;
    return transition;
}

+ (id)pushTransitionWithDuration:(CMTime)duration direction:(DLYPushTransitionDirection)direction {
    DLYVideoTransition *transition = [self videoTransition];
    transition.type = DLYVideoTransitionTypePush;
    transition.duration = duration;
    transition.direction = direction;
    return transition;
}

- (id)init {
    self = [super init];
    if (self) {
        _type = DLYVideoTransitionTypeDissolve;
        _timeRange = kCMTimeRangeInvalid;
    }
    return self;
}

- (void)setDirection:(DLYPushTransitionDirection)direction {
    if (self.type == DLYVideoTransitionTypePush) {
        _direction = direction;
    } else {
        _direction = DLYPushTransitionDirectionInvalid;
        NSAssert(NO, @"Direction can only be specified for a type == ZHVideoTransitionTypePush.");
    }
}

@end
