//
//  DLYTransitionComposition.h
//  OneMinute
//
//  Created by chenzonghai on 14/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYTransitionComposition : NSObject

@property (nonatomic, strong) AVComposition                          *composition;
@property (nonatomic, strong, readonly) AVVideoComposition           *videoComposition;
@property (nonatomic, strong, readonly) AVAudioMix                   *audioMax;

-(id)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition andAudioMax:(AVAudioMix *)audioMax;
- (AVPlayerItem *) makePlayable;
- (AVAssetExportSession *) makeExportable;

@end
