//
//  DLYTransitionInstruction.h
//  OneMinute
//
//  Created by chenzonghai on 14/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DLYVideoTransition.h"

@interface DLYTransitionInstructions : NSObject

@property (strong, nonatomic) AVMutableVideoCompositionInstruction *compositionInstruction;
@property (strong, nonatomic) AVMutableVideoCompositionLayerInstruction *fromLayerInstruction;
@property (strong, nonatomic) AVMutableVideoCompositionLayerInstruction *toLayerInstruction;
@property (strong, nonatomic) DLYVideoTransition *transition;

@end
