

//
//  DLYTransitionComposition.m
//  OneMinute
//
//  Created by chenzonghai on 14/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYTransitionComposition.h"

@implementation DLYTransitionComposition

-(id)initWithComposition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition andAudioMax:(AVAudioMix *)audioMax{
    if(self = [super init]){
        _composition = composition;
        _videoComposition = videoComposition;
        _audioMax = audioMax;
    }
    return self;
}

- (AVPlayerItem *) makePlayable{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:[self.composition copy]];
    
    playerItem.audioMix = self.audioMax;
    playerItem.videoComposition = self.videoComposition;
    
    return playerItem;
}

- (AVAssetExportSession *) makeExportable{
    
    NSString *prenset = AVSampleRateConverterAudioQualityKey;
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:[self.composition copy] presetName:prenset];
    exportSession.audioMix = self.audioMax;
    exportSession.videoComposition = self.videoComposition;
    return exportSession;
}

@end
