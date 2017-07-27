//
//  DLYAVEngine.h
//  OneMinute
//
//  Created by chenzonghai on 19/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import <CoreMedia/CoreMedia.h>
#import "DLYMiniVlogPart.h"

typedef NS_ENUM(NSUInteger, DLYCameraType) {
    DLYCameraTypeBack,
    DLYCameraTypeFront,
};

typedef void (^TimeLapseSamplebufferBlock)(CMSampleBufferRef sampleBuffer);
typedef void (^OnBufferBlock)(CMSampleBufferRef sampleBuffer);

typedef void(^SuccessBlock)(void);
typedef void(^FailureBlock)(NSError *error);

@protocol DLYCaptureManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;
@end

@interface DLYAVEngine : DLYModule<AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,CAAnimationDelegate>

@property (nonatomic, assign) id                                                      delegate;
@property (nonatomic, readonly) BOOL                                                  isRecording;
@property (nonatomic, copy) OnBufferBlock                                             onBuffer;
@property (nonatomic, copy) TimeLapseSamplebufferBlock                                timeLapseSamplebufferBlock;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer                              *previewLayer;
@property (nonatomic, strong) AVCaptureConnection                                     *videoConnection;
@property (nonatomic, strong) AVCaptureSession                                        *captureSession;
@property (nonatomic, strong) DLYMiniVlogPart                                         *currentPart;
@property (nonatomic, strong) NSURL                                                   *currentProductUrl;
@property (nonatomic, assign) BOOL                                                     isTime;
@property (nonatomic, strong) NSMutableArray                                          *imageArray;

/**
 初始化相机
 */
- (void) initializationRecorder;
- (instancetype)initWithPreviewView:(UIView *)previewView;
/**
 按传入的片段信息开始录制

 @param part info
 */
- (void)startRecordingWithPart:(DLYMiniVlogPart *)part;

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

/**
 合并片段

 @param successBlock 成功回调
 @param failureBlcok 失败回调
 */

/**
 合并片段

 @param successBlock 成功回
 @param failureBlcok 失败回调
 */
- (void) mergeVideoWithSuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok;

/**
 添加转场效果

 @param successBlock 成功回调
 @param failureBlcok 失败回调
 */
- (void) addTransitionEffectSuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok;
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point;
@end
