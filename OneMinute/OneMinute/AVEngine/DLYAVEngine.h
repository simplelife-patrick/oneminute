//
//  DLYAVEngine.h
//  OneMinute
//
//  Created by chenzonghai on 19/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import <CoreMedia/CoreMedia.h>

typedef NS_ENUM(NSUInteger, DLYCameraType) {
    DLYCameraTypeBack,
    DLYCameraTypeFront,
};

typedef NS_ENUM(NSUInteger, DLYOutputModeType) {
    DLYOutputModeVideoData,
    DLYOutputModeMovieFile,
};
typedef NS_ENUM(NSUInteger, DLYRecordModelType) {
    DLYRecordNormalMode,
    DLYRecordSlomoMode,
    DLYRecordTimeLapseMode,
};

typedef void (^TimeLapseSamplebufferBlock)(CMSampleBufferRef sampleBuffer);
typedef void (^OnBufferBlock)(CMSampleBufferRef sampleBuffer);

@protocol DLYCaptureManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;
@end

@interface DLYAVEngine : DLYModule

@property (nonatomic, assign) id<DLYCaptureManagerDelegate>          delegate;
@property (nonatomic, readonly) BOOL                                isRecording;
@property (nonatomic, copy) OnBufferBlock                           onBuffer;
@property (nonatomic, copy) TimeLapseSamplebufferBlock              timeLapseSamplebufferBlock;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer            *previewLayer;
@property (nonatomic, strong) AVCaptureConnection                   *videoConnection;
@property (nonatomic, strong) AVCaptureSession                      *captureSession;;


/**
 初始化相机
 */
- (void) initializationRecorder;
/**
 开始录制
 */
- (void)startRecording;

/**
 停止录制
 */
- (void)stopRecording;

/**
 取消录制
 */
- (void)cancelRecording;

/**
 切换摄像头

 @param isFront 是否是前置摄像头
 */
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;


@end
