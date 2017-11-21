//
//  AVManager.h
//  AVEngineDemo
//
//  Created by APPLE on 2017/11/16.
//  Copyright © 2017年 LDJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol AVManagerDelegate <NSObject>
- (void)didFinishRecordingWithError:(NSError *)error;
- (void)didFinishSaveToPhotoAlbumWithError:(NSError *)error;
@end


@interface AVManager : NSObject
@property (nonatomic, assign) id<AVManagerDelegate> delegate;
@property (nonatomic, assign) double scale;
- (instancetype)initWithPreviewView:(UIView *)previewView;
- (void)stopVideoRecoding;
- (void)startRecordVideoWithDuration:(NSInteger)durationMS AndScale:(double)scale;

@end
