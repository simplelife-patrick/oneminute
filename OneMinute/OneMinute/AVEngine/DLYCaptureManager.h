//
//  DLYCaptureManager.h
//  OneMinute
//
//  Created by chenzonghai on 11/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
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

@interface DLYCaptureManager : NSObject

@property (nonatomic, assign) id<DLYCaptureManagerDelegate>          delegate;
@property (nonatomic, readonly) BOOL                                isRecording;
@property (nonatomic, copy) OnBufferBlock                           onBuffer;
@property (nonatomic, copy) TimeLapseSamplebufferBlock              timeLapseSamplebufferBlock;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer            *previewLayer;
@property (nonatomic, strong) AVCaptureConnection                   *videoConnection;
@property (nonatomic, strong) AVCaptureSession                      *captureSession;;

- (instancetype)initWithPreviewView:(UIView *)previewView outputMode:(DLYOutputModeType)outputModeType;
- (void)toggleContentsGravity;
- (void)resetFormat;
- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS;
- (void)startRecording;
- (void)stopRecording;
- (void)updateOrientationWithPreviewView:(UIView *)previewView;

- (UIImage*)getKeyImage:(NSURL *)assetUrl intervalTime:(NSInteger)intervalTime;
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point;
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation;

@end
