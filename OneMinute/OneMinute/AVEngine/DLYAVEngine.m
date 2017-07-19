//
//  DLYAVEngine.m
//  OneMinute
//
//  Created by chenzonghai on 19/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYAVEngine.h"
#import "DLYMobileDevice.h"
#import "DLYResource.h"
#import <GPUImageMovie.h>
#import <GPUImageMovieWriter.h>
#import <GPUImageChromaKeyBlendFilter.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "DLYResource.h"
#import "DLYTransitionComposition.h"
#import "DLYTransitionInstructions.h"
#import "DLYVideoTransition.h"
#import "DLYResource.h"

typedef void(^SuccessBlock)(void);
typedef void(^FailureBlock)(NSError *error);

@interface DLYAVEngine ()<AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate,CAAnimationDelegate>
{
    CMTime defaultVideoMaxFrameDuration;
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureVideoOrientation referenceOrientation;
    dispatch_queue_t movieWritingQueue;
    CMBufferQueueRef previewBufferQueue;
    BOOL recordingWillBeStarted;
    DLYOutputModeType currentOutputMode;
    
    long long _startTime;
    long long _finishTime;
    CGSize videoSize;
}

@property (nonatomic, strong) AVCaptureVideoDataOutput          *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioOutput;//音频输出
@property (nonatomic, strong) AVCaptureMovieFileOutput          *movieFileOutput;
@property (nonatomic, strong) AVCaptureDeviceInput              *currentVideoDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *backCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *audioMicInput;//麦克风输入
@property (nonatomic, strong) AVCaptureDeviceFormat             *defaultFormat;
@property (nonatomic, strong) NSURL                             *fileURL;
@property (nonatomic, strong) AVCaptureDevice                   *videoDevice;
@property (nonatomic, strong) AVCaptureConnection               *audioConnection;

// for video data output
@property (nonatomic, strong) AVAssetWriter                     *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterAudioInput;
@property (nonatomic, copy)   NSMutableArray                    *imageArray;

@property (nonatomic, strong) GPUImageMovie *alphaMovie;
@property (nonatomic, strong) GPUImageMovie *bodyMovie;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) GPUImageChromaKeyBlendFilter *filter;
typedef void ((^MixcompletionBlock) (NSURL *outputUrl));

@property (nonatomic, strong) AVMutableComposition          *composition;
@property (nonatomic, strong) NSMutableArray                *passThroughTimeRanges;
@property (nonatomic, strong) NSMutableArray                *transitionTimeRanges;
@property (nonatomic, strong) UIImagePickerController       *moviePicker;
@property (nonatomic, copy)   NSMutableArray                *videoPathArray;

@end

@implementation DLYAVEngine

- (BOOL)shouldAutorotate
{
    return NO;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
    [_captureSession stopRunning];
    _captureSession   = nil;
    _previewLayer     = nil;
    _backCameraInput  = nil;
    _frontCameraInput = nil;
    _audioOutput      = nil;
    _videoOutput      = nil;
    _audioConnection  = nil;
    _videoConnection  = nil;
}

-(NSMutableArray *)imageArray{
    if (_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}
- (void) initializationRecorder{
    
//    self.captureManager = [[DLYCaptureManager alloc] initWithPreviewView:self.previewView outputMode:DLYOutputModeVideoData];
//    
//    self.captureManager.delegate = self;
}
-(AVCaptureSession *)captureSession{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        
        //添加后置摄像头的输出
        if ([_captureSession canAddInput:self.backCameraInput]) {
            [_captureSession addInput:self.backCameraInput];
            
        }
        //添加后置麦克风的输出
        if ([_captureSession canAddInput:self.audioMicInput]) {
            [_captureSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_captureSession canAddOutput:self.audioOutput]) {
            [_captureSession addOutput:self.audioOutput];
        }
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _captureSession;
}
- (instancetype)initWithPreviewView:(UIView *)previewView{
    if (self = [super init]) {
        
        referenceOrientation = (AVCaptureVideoOrientation)UIDeviceOrientationPortrait;
        
        NSError *error;
        
        self.captureSession = [[AVCaptureSession alloc] init];
        
        DLYMobileDevice *mobileDevice = [DLYMobileDevice sharedDevice];
        DLYPhoneDeviceType phoneType = [mobileDevice iPhoneType];
        
        NSString *phoneModel = [mobileDevice iPhoneModel];
        
        DLYLog(@"Current Phone Type: %@\n",phoneModel);
        if (phoneType == PhoneDeviceTypeIphone_7 || phoneType == PhoneDeviceTypeIphone_7_Plus) {
            self.captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
        }else if (phoneType == PhoneDeviceTypeIphone_6 || phoneType == PhoneDeviceTypeIphone_6_Plus){
            self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        }else if (phoneType == PhoneDeviceTypeIphone_6s || phoneType == PhoneDeviceTypeIphone_6s_Plus || phoneType == PhoneDeviceTypeIphone_SE){
            self.captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
        }
        //添加后置摄像头的输入
        if ([_captureSession canAddInput:self.backCameraInput]) {
            [_captureSession addInput:self.backCameraInput];
            _currentVideoDeviceInput = self.backCameraInput;
        }else{
            DLYLog(@"Back camera intput add faild");
        }
        //添加麦克风的输入
        if ([_captureSession canAddInput:self.audioMicInput]) {
            [_captureSession addInput:self.audioMicInput];
        }else{
            DLYLog(@"Mic input add faild");
        }
        
        if (error) {
            DLYLog(@"Video input creation failed");
            return nil;
        }
        
        // save the default format
        self.defaultFormat = self.videoDevice.activeFormat;
        defaultVideoMaxFrameDuration = self.videoDevice.activeVideoMaxFrameDuration;
        
        if (previewView) {
            self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
            self.previewLayer.orientation = UIDeviceOrientationLandscapeLeft;
            self.previewLayer.frame = previewView.bounds;
            self.previewLayer.contentsGravity = kCAGravityTopLeft;
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [previewView.layer insertSublayer:self.previewLayer atIndex:0];
        }
        
        //添加视频输出
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }else{
            DLYLog(@"Video output creation faild");
        }
        //添加音频输出
        if ([_captureSession canAddOutput:self.audioOutput]) {
            [_captureSession addOutput:self.audioOutput];
        }else{
            DLYLog(@"Audio output creation faild");
        }
        //设置视频录制的方向
        if ([self.videoConnection isVideoOrientationSupported]) {
            
            [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
        // Video
        movieWritingQueue = dispatch_queue_create("moviewriting", DISPATCH_QUEUE_SERIAL);
        videoOrientation = [self.videoConnection videoOrientation];
        
        // BufferQueue
        OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
        DLYLog(@"CMBufferQueueCreate error:%d", (int)err);

        [self.captureSession startRunning];
    }
    return self;
}
#pragma mark - 切换摄像头 -
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    if (isFront) {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.backCameraInput];
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.frontCameraInput];
        }
    }else {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.backCameraInput];
        }
    }
    [self.captureSession startRunning];
}
//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            DLYLog(@"获取后置摄像头失败~");
        }
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            DLYLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}
//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            DLYLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}
-(AVCaptureMovieFileOutput *)movieFileOutput{
    if (_movieFileOutput == nil) {
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _movieFileOutput;
}
//视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
        dispatch_queue_t videoCaptureQueue = dispatch_queue_create("videocapture", NULL);
        [_videoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        //        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create("audiocapture", DISPATCH_QUEUE_SERIAL);
        [_audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    }
    return _audioOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}
//返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}
//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            
            // save the default format
            self.defaultFormat = device.activeFormat;
            defaultVideoMaxFrameDuration = device.activeVideoMaxFrameDuration;
            DLYLog(@"videoDevice.activeFormat:%@", device.activeFormat);
            return device;
        }
    }
    return nil;
}

//摄像头切换动画
- (void)changeCameraAnimation {
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.3;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromBottom;
    //    changeAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}
- (void)animationDidStart:(CAAnimation *)anim {
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.captureSession startRunning];
}

#pragma mark -旋转屏幕-
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = [[DLYAVEngine alloc ] angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [[DLYAVEngine alloc] angleOffsetFromPortraitOrientationToOrientation:videoOrientation];
    
    // Find the difference in angle between the passed in orientation and the current video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    return transform;
}
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGFloat angle = 0.0;
    
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    DLYLog(@"当前旋转角度 :%f",angle);
    
    return angle;
}
- (void)updateOrientationWithPreviewView:(UIView *)previewView {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    // Don't update the reference orientation when the device orientation is face up/down or unknown.
    if (UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation)) {
        referenceOrientation = (AVCaptureVideoOrientation)orientation;
    }
    
    [[self.previewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
    
    readyToRecordVideo = NO;
}
#pragma mark - 点触设置曝光 -
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = _currentVideoDeviceInput.device;
    
    [_currentVideoDeviceInput.device lockForConfiguration:nil];
    
    // 设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    // 设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:point];
    }
    
    //设置白平衡
    if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }
    [_currentVideoDeviceInput.device unlockForConfiguration];
}

#pragma mark -视频数据输出设置-

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
                                               nil], AVVideoCompressionPropertiesKey,
                                              nil];
    
    DLYLog(@"videoCompressionSetting:%@", videoCompressionSettings);
    
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:referenceOrientation];
        
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
        else {
            DLYLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }
    else {
        DLYLog(@"Couldn't apply video output settings.");
        return NO;
    }
    return YES;
}

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    NSData *currentChannelLayoutData = nil;
    
    if ( currentChannelLayout && aclSize > 0 ) {
        
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    }
    else {
        currentChannelLayoutData = [NSData data];
    }
    
    NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                              [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
                                              [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
                                              [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                              currentChannelLayoutData, AVChannelLayoutKey,
                                              nil];
    if ([self.assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                    outputSettings:audioCompressionSettings];
        
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        else {
            
            DLYLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else {
        
        DLYLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        
        if ([self.assetWriter startWriting]) {
            
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [self.assetWriter startSessionAtSourceTime:timestamp];
        }
        else {
            
            DLYLog(@"AVAssetWriter startWriting error:%@", self.assetWriter.error);
        }
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        
        if (mediaType == AVMediaTypeVideo) {
            
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                
                if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                    
                    DLYLog(@"isRecording:%d, willBeStarted:%d", self.isRecording, recordingWillBeStarted);
                    DLYLog(@"AVAssetWriterInput video appendSapleBuffer error:%@", self.assetWriter.error);
                }
            }
        }
        else if (mediaType == AVMediaTypeAudio) {
            
            if (self.assetWriterAudioInput.readyForMoreMediaData) {
                
                if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                    
                    DLYLog(@"AVAssetWriterInput audio appendSapleBuffer error:%@", self.assetWriter.error);
                }
            }
        }
    }
}

#pragma mark - Public

- (void)toggleContentsGravity {
    
    if ([self.previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    else {
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (void)resetFormat {
    
    BOOL isRunning = self.captureSession.isRunning;
    
    if (isRunning) {
        [self.captureSession stopRunning];
    }
    
    [_videoDevice lockForConfiguration:nil];
    _videoDevice.activeFormat = self.defaultFormat;
    _videoDevice.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
    [_videoDevice unlockForConfiguration];
    
    if (isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    BOOL isRunning = self.captureSession.isRunning;
    if (isRunning)  [self.captureSession stopRunning];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= desiredFPS && desiredFPS <= range.maxFrameRate && width >= maxWidth) {
                
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    
    if (selectedFormat)
    {
        if ([videoDevice lockForConfiguration:nil]) {
            
            DLYLog(@"selected format:%@", selectedFormat);
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);//设置帧率
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [videoDevice unlockForConfiguration];
        }
    }
    
    if (isRunning) [self.captureSession startRunning];
}
#pragma mark - 开始录制 -
- (void)startRecording {
        
    dispatch_async(movieWritingQueue, ^{
        
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        // Don't update the reference orientation when the device orientation is face up/down or unknown.
        if (UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation)) {
            referenceOrientation = (AVCaptureVideoOrientation)orientation;
        }
        
        DLYResource *resource = [[DLYResource alloc] init];
        self.fileURL = [resource saveToSandboxWithPath:kDraftFolder suffixType:@".mp4"];
        
        NSError *error;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL fileType:AVFileTypeMPEG4 error:&error];
        DLYLog(@"AVAssetWriter error:%@", error);
        
        recordingWillBeStarted = YES;
        
        //        [self.assetWriter startWriting];
        //        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    });
}
#pragma mark - 停止录制 -
- (void)stopRecording {
        
    dispatch_async(movieWritingQueue, ^{
        
        _isRecording = NO;
        readyToRecordVideo = NO;
        readyToRecordAudio = NO;
        
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            self.assetWriterVideoInput = nil;
            self.assetWriterAudioInput = nil;
            self.assetWriter = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
                    [self.delegate didFinishRecordingToOutputFileAtURL:self.fileURL error:nil];
                }
            });
        }];
    });
}
#pragma mark - 取消录制 -
- (void)cancelRecording{
    dispatch_async(movieWritingQueue, ^{
        
        _isRecording = NO;
        readyToRecordVideo = NO;
        readyToRecordAudio = NO;
        
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            self.assetWriterVideoInput = nil;
            self.assetWriterAudioInput = nil;
            self.assetWriter = nil;
        }];
    });
}
#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    _isRecording = YES;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    //    [self saveRecordedFile:outputFileURL];
    _isRecording = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
        [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (self.onBuffer) {
        self.onBuffer(sampleBuffer);
    }
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CFRetain(sampleBuffer);
    
    dispatch_async(movieWritingQueue, ^{
        
        if (self.assetWriter && (self.isRecording || recordingWillBeStarted)) {
            
            BOOL wasReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
            
            if (connection == self.videoConnection) {
                // Initialize the video input if this is not done yet
                if (!readyToRecordVideo) {
                    readyToRecordVideo = [self setupAssetWriterVideoInput:formatDescription];
                }
                
                // Write video data to file
                if (readyToRecordVideo && readyToRecordAudio) {
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                }
            }
            else if (connection == self.audioConnection) {
                // Initialize the audio input if this is not done yet
                if (!readyToRecordAudio) {
                    readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
                }
                
                // Write audio data to file
                if (readyToRecordAudio && readyToRecordVideo)
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
            }
            
            BOOL isReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
            if (!wasReadyToRecord && isReadyToRecord) {
                recordingWillBeStarted = NO;
                _isRecording = YES;
            }
        }
        CFRelease(sampleBuffer);
    });
}
#pragma mark -延时拍摄-
//获取视频某一帧图像
-(UIImage*)getKeyImage:(NSURL *)assetUrl intervalTime:(NSInteger)intervalTime{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:assetUrl options:nil];
    NSParameterAssert(asset);
    if (!asset) {
        return nil;
    }
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    for (AVAssetTrack *track in videoTracks) {
        if (track.naturalSize.width > 0 && track.naturalSize.height > 0) {
            assetImageGenerator.maximumSize = CGSizeMake(track.naturalSize.width, track.naturalSize.height);
        }else{
            assetImageGenerator.maximumSize = CGSizeMake(480, 853);
        }
    }
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(intervalTime, 2) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        DLYLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    return thumbnailImage;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    CGImageRelease(quartzImage);
    
    return (image);
}
#pragma mark - 合并 -

-(void)mergeVideoToOneVideo:(NSArray *)videoArray outputUrl:(NSURL *)storeUrl success:(void (^)(long long finishTime))successBlock failure:(void (^)(void))failureBlcok{
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    Float64 tmpDuration =0.0f;
    for (int i=0; i < videoArray.count; i++)
    {
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:videoArray[i] options:nil];
        
        NSError *error;
        AVAssetTrack *videoAssetTrack = nil;
        AVAssetTrack *audioAssetTrack = nil;
        if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count!= 0) {
            audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration);
        [compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        [compositionAudioTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:nil];
        tmpDuration += CMTimeGetSeconds(videoAssetTrack.timeRange.duration);
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1920x1080];
    exporter.outputURL = storeUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        UISaveVideoAtPathToSavedPhotosAlbum([storeUrl path], self, nil, nil);
        
        _finishTime = [self getDateTimeTOMilliSeconds:[NSDate date]];
        successBlock(_finishTime);
    }];
}

-(AVMutableComposition *)mergeVideostoOnevideo:(NSArray*)array
{
    DLYLog(@"array:%@",array);
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    Float64 tmpDuration =0.0f;
    for (int i=0; i<array.count; i++)
    {
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:array[i] options:nil];
        
        NSError *error;
        AVAssetTrack *videoAssetTrack = nil;
        AVAssetTrack *audioAssetTrack = nil;
        if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count!= 0) {
            audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration);
        [compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        [compositionAudioTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:nil];
        tmpDuration += CMTimeGetSeconds(videoAssetTrack.timeRange.duration);
    }
    return mixComposition;
}

-(long long)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval*1000 ;
    return totalMilliseconds;
}
#pragma mark - 转场 -
- (void)buildCompositionTracks {
    
    self.composition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    
    AVMutableCompositionTrack *compositionTrackA =                          // 1
    [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                  preferredTrackID:trackID];
    
    AVMutableCompositionTrack *compositionTrackB =
    [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                  preferredTrackID:trackID];
    
    AVMutableCompositionTrack *compositionTrackAudio =
    [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                  preferredTrackID:trackID];
    
    NSArray *videoTracks = @[compositionTrackA, compositionTrackB];
    
    //    AVURLAsset *asetA = [[AVURLAsset alloc]initWithURL:[NSURL URLWithString:[[NSBundle mainBundle]  pathForResource:@"01_nebula.mp4" ofType:nil]] options:nil];
    //    AVURLAsset *assetB = [[AVURLAsset alloc]initWithURL:[NSURL URLWithString:[[NSBundle mainBundle]  pathForResource:@"02_blackhole.mp4" ofType:nil]] options:nil];
    
    //    NSArray *videos = @[asetA,assetB];
    
    CMTime videoCursorTime = kCMTimeZero;
    CMTime transitionDuration = CMTimeMake(2, 1);
    CMTime audioCursorTime = kCMTimeZero;
    
    for (NSUInteger i = 0; i < self.videoPathArray.count; i++) {
        
        NSUInteger trackIndex = i % 2;                                      // 3
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.videoPathArray[i] options:nil];
        DLYLog(@"self.videoPathArray[%lu]: %@",(unsigned long)i,self.videoPathArray[i]);
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        
        if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        AVMutableCompositionTrack *currentTrack = videoTracks[trackIndex];
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, assetVideoTrack.timeRange.duration);
        
        [currentTrack insertTimeRange:timeRange
                              ofTrack:assetVideoTrack
                               atTime:videoCursorTime error:nil];
        [compositionTrackAudio insertTimeRange:timeRange
                                       ofTrack:assetAudioTrack
                                        atTime:audioCursorTime error:nil];
        // Overlap clips by transition duration                             // 4
        videoCursorTime = CMTimeAdd(videoCursorTime, timeRange.duration);
        videoCursorTime = CMTimeSubtract(videoCursorTime, transitionDuration);
        audioCursorTime = CMTimeAdd(audioCursorTime, timeRange.duration);
        
        if (i + 1 < self.videoPathArray.count) {
            timeRange = CMTimeRangeMake(videoCursorTime, transitionDuration);
            NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            [self.transitionTimeRanges addObject:timeRangeValue];
        }
    }
    
}
- (AVVideoComposition *)buildVideoComposition {
    
    AVVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.composition];
    
    NSArray *transitionInstructions = [self transitionInstructionsInVideoComposition:videoComposition];
    
    for (DLYTransitionInstructions *instructions in transitionInstructions) {
        
        CMTimeRange timeRange = instructions.compositionInstruction.timeRange;
        
        AVMutableVideoCompositionLayerInstruction *fromLayer = instructions.fromLayerInstruction;
        
        AVMutableVideoCompositionLayerInstruction *toLayer = instructions.toLayerInstruction;
        
        //        DLYVideoTransitionType type = instructions.transition.type;
        
        //        if (type == DLYVideoTransitionTypeDissolve) {//溶解
        //
        [fromLayer setOpacityRampFromStartOpacity:1.0
                                     toEndOpacity:0.0
                                        timeRange:timeRange];
        //        }
        
        CGAffineTransform identityTransform = CGAffineTransformIdentity;
        
        CGFloat videoWidth = videoComposition.renderSize.width;
        
        CGAffineTransform toStartTransform = CGAffineTransformMakeRotation(-M_PI_2);
        
        CGAffineTransform fromDestTransform =CGAffineTransformInvert(CGAffineTransformMakeScale(2, 2));
        
        instructions.compositionInstruction.layerInstructions = @[fromLayer,toLayer];
    }
    return videoComposition;
}
- (NSArray *)transitionInstructionsInVideoComposition:(AVVideoComposition *)vc {
    
    NSMutableArray *transitionInstructions = [NSMutableArray array];
    
    int layerInstructionIndex = 1;
    
    NSArray *compositionInstructions = vc.instructions;                     // 1
    
    for (AVMutableVideoCompositionInstruction *vci in compositionInstructions) {
        
        if (vci.layerInstructions.count == 2) {                             // 2
            
            DLYTransitionInstructions *instructions = [[DLYTransitionInstructions alloc] init];
            
            instructions.compositionInstruction = vci;
            
            instructions.fromLayerInstruction =                             // 3
            (AVMutableVideoCompositionLayerInstruction *)vci.layerInstructions[1 - layerInstructionIndex];
            
            instructions.toLayerInstruction =
            (AVMutableVideoCompositionLayerInstruction *)vci.layerInstructions[layerInstructionIndex];
            
            [transitionInstructions addObject:instructions];
            
            layerInstructionIndex = layerInstructionIndex == 1 ? 0 : 1;
        }
    }
    
    for (NSUInteger i = 0; i < transitionInstructions.count; i++) {
        DLYTransitionInstructions *tis = transitionInstructions[i];
        
        DLYVideoTransition *transition = [DLYVideoTransition videoTransition];
        transition.type = DLYVideoTransitionTypePush;
        transition.direction = DLYPushTransitionDirectionLeftToRight;
        tis.transition = transition;
    }
    
    return transitionInstructions;
}
#pragma mark - 配音 -
- (void) addMusicToVideo:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl completion:(MixcompletionBlock)completionHandle
{
    //加载素材
    AVAsset *videoAsset = [AVAsset assetWithURL:videoUrl];
    AVAsset *audioAsset = [AVAsset assetWithURL:audioUrl];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    //
    //创建视频编辑工程
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //将视音频素材加入编辑工程
    AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //调整视频方向
    [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
    
    //处理视频原声
    AVAssetTrack *originalAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVMutableCompositionTrack *originalAudioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    //AVAssetExportSession用于合并文件，导出合并后文件，presetName文件的输出类型
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    
    //混合后的视频输出路径
    CocoaSecurityResult * result = [CocoaSecurity md5:[[NSDate date] description]];
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDir = [homeDir objectAtIndex:0];
    NSString *filePath = [documentsDir stringByAppendingPathComponent:@"DubbedVideos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",filePath, result.hex];
    
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    
    //控制音量
    CMTime duration = videoAssetTrack.timeRange.duration;
    CGFloat videoDuration = duration.value / (float)duration.timescale;
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *videoParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:originalAudioCompositionTrack];
    AVMutableAudioMixInputParameters *BGMParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
    
    [BGMParameters setVolume:5  atTime:kCMTimeZero];
    [BGMParameters setVolume:0  atTime:CMTimeMake(15, 1)];
    
    [videoParameters setVolume:5  atTime:CMTimeMake(15, 1)];
    [videoParameters setVolume:0  atTime:CMTimeMake(30, 1)];
    
    [BGMParameters setVolume:5  atTime:CMTimeMake(30, 1)];
    [BGMParameters setVolume:0  atTime:CMTimeMake(45, 1)];
    
    [videoParameters setVolume:5  atTime:CMTimeMake(45, 1)];
    [videoParameters setVolume:0  atTime:CMTimeMake(60, 1)];
    
    [BGMParameters setVolume:5  atTime:CMTimeMake(60, 1)];
    
    
    //    [BGMParameters setVolumeRampFromStartVolume:0 toEndVolume:5 timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(15, 1))];//BGM
    //    [videoParameters setVolumeRampFromStartVolume:0 toEndVolume:5 timeRange:CMTimeRangeMake(CMTimeMake(15, 1), CMTimeMake(30, 1))];//original
    //
    //    [BGMParameters setVolumeRampFromStartVolume:0 toEndVolume:5 timeRange:CMTimeRangeMake(CMTimeMake(30, 1), CMTimeMake(45, 1))];//BGM
    //    [videoParameters setVolumeRampFromStartVolume:0 toEndVolume:5 timeRange:CMTimeRangeMake(CMTimeMake(45, 1), CMTimeMake(60, 1))];//original
    
    audioMix.inputParameters = @[videoParameters,BGMParameters];
    
    //输出设置
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.audioMix = audioMix;
    assetExportSession.outputURL = outPutUrl;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExportSession status]) {
            case AVAssetExportSessionStatusFailed:{
                DLYLog(@"合成失败: %@",[[assetExportSession error] description]);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                UISaveVideoAtPathToSavedPhotosAlbum([outPutUrl path], self, nil, nil);
                DLYLog(@"合成成功");
            }break;
            default:
                break;
        }
        completionHandle(outPutUrl);
    }];
}
#pragma mark - 叠加 -
- (void) overlayVideoForBodyVideoAction{
    
    NSURL *alphaUrl = [[NSBundle mainBundle] URLForResource:@"testheadergreenh264" withExtension:@"mp4"];
    NSURL *bodyUrl = [[NSBundle mainBundle] URLForResource:@"01_nebula" withExtension:@"mp4"];
    
    AVURLAsset *bodyAsset = [AVURLAsset URLAssetWithURL:bodyUrl options:nil];
    AVAssetTrack *videoTrack = [[bodyAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    videoSize = videoTrack.naturalSize;
    
    self.bodyMovie = [[GPUImageMovie alloc]initWithURL:bodyUrl];
    self.alphaMovie = [[GPUImageMovie alloc]initWithURL:alphaUrl];
    
    self.filter = [[GPUImageChromaKeyBlendFilter alloc] init];
    
    [self.alphaMovie addTarget:self.filter];
    [self.bodyMovie addTarget:self.filter];
    
    DLYResource *resource = [[DLYResource alloc]init];
    NSURL *outputUrl = [resource saveToSandboxWithPath:kVideoHeaderFolder suffixType:@".mp4"];
    
    self.movieWriter =  [[GPUImageMovieWriter alloc] initWithMovieURL:outputUrl size:videoSize];
    
    [self.filter addTarget:self.movieWriter];
    
    [self.movieWriter startRecording];
    [self.bodyMovie startProcessing];
    [self.alphaMovie startProcessing];
    
    __weak typeof(self) weakSelf = self;
    
    [self.movieWriter setCompletionBlock:^{
        
        [weakSelf.alphaMovie endProcessing];
        [weakSelf.bodyMovie endProcessing];
        [weakSelf.movieWriter finishRecording];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // 保存到相册
            //            [weakSelf writeToAlbum:outputUrl];
        });
    }];
}
#pragma mark - 截取 -
-(void)trimVideoByRange:(NSURL *)assetUrl startTime:(CMTime)startTime stop:(CMTime)stopTime{
    
    AVAsset *selectedAsset = [AVAsset assetWithURL:assetUrl];
    AVAssetTrack *videoAssertTrack = nil;
    AVAssetTrack *audioAssertTrack = nil;
    
    if ([[selectedAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0]) {
        videoAssertTrack = [[selectedAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    }
    if ([[selectedAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]) {
        audioAssertTrack = [[selectedAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime,stopTime);
    
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:videoAssertTrack atTime:kCMTimeZero error:nil];
    [audioCompositionTrack insertTimeRange:videoTimeRange ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionLayerInstruction *videoCompositionLayerIns = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssertTrack];
    [videoCompositionLayerIns setTransform:videoAssertTrack.preferredTransform atTime:kCMTimeZero];
    
    //得到视频素材
    AVMutableVideoCompositionInstruction *videoCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [videoCompositionIns setTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssertTrack.timeRange.duration)];
    //得到视频轨道
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoCompositionIns];
    videoComposition.renderSize = CGSizeMake(videoAssertTrack.naturalSize.height,videoAssertTrack.naturalSize.width);
    //裁剪出对应的大小
    //value视频的总帧数，timescale是指每秒视频播放的帧数，视频播放速率，（value / timescale）才是视频实际的秒数时长
    videoComposition.frameDuration = CMTimeMake(1, 60);
    
    //调整视频方向
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssertTrack];
    [layerInst setTransform:videoAssertTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, selectedAsset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
}

@end
