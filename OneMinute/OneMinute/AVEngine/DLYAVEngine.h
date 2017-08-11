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

@interface DLYAVEngine : DLYModule

@property (nonatomic, strong) AVCaptureDeviceInput                                    *currentVideoDeviceInput;
@property (nonatomic, strong) AVCaptureDevice                                         *videoDevice;
@property (nonatomic, assign) id                                                      delegate;
@property (nonatomic, readonly) BOOL                                                  isRecording;
@property (nonatomic, copy) OnBufferBlock                                             onBuffer;
@property (nonatomic, copy) TimeLapseSamplebufferBlock                                timeLapseSamplebufferBlock;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer                              *previewLayer;
@property (nonatomic, strong) AVCaptureConnection                                     *videoConnection;
@property (nonatomic, strong) AVCaptureSession                                        *captureSession;
@property (nonatomic, strong) DLYMiniVlogPart                                         *currentPart;
@property (nonatomic, strong) NSURL                                                   *currentProductUrl;
@property (nonatomic, assign) BOOL                                                    isTime;
@property (nonatomic, strong) NSMutableArray                                          *imageArray;


/**
 初始化录制组件

 @param previewView 预览视图
 @return 返回加载好的Recorder component
 */
- (instancetype)initWithPreviewView:(UIView *)previewView;

/**
 切换摄像头旋转动画
 */
- (void)changeCameraAnimation;
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

 @param successBlock 成功回
 @param failureBlcok 失败回调
 */
- (void) mergeVideoWithVideoTitle:(NSString *)videoTitle SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok;

/**
 合并并添加转场效果

 @param videoTitle 视频标题
 @param successBlock 成功回调
 @param failureBlcok 失败回调
 */
- (void) addTransitionEffectWithTitle:(NSString *)videoTitle SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok;

/**
 获取视频某一帧图片
 
 @param assetUrl 视频URL
 @param intervalTime 某一时刻
 @return 返回获取的图片
 */
-(UIImage*)getKeyImage:(NSURL *)assetUrl intervalTime:(NSInteger)intervalTime;

-(void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point;

/**
 创建导出会话
 */
- (void) makeExportable;
@end
