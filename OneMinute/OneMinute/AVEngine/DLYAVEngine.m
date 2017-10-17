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
#import "DLYSession.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <math.h>
#import "DLYMovieObject.h"
#import <CoreMotion/CoreMotion.h>
#import "DLYThemesData.h"
#import "DLYVideoFilter.h"

typedef void ((^MixcompletionBlock) (NSURL *outputUrl));

@interface DLYAVEngine ()<AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,CAAnimationDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    CMTime defaultVideoMaxFrameDuration;
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;
    BOOL recordingWillBeStarted;
    
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureVideoOrientation referenceOrientation;
    dispatch_queue_t movieWritingQueue;
    CMBufferQueueRef previewBufferQueue;
    
    CMTime _startTime;
    CMTime _stopTime;
    CMTime _prePoint;
    CGSize videoSize;
    NSURL *fileUrl;
    CGRect faceRegion;
    CGRect lastFaceRegion;
    BOOL isDetectedMetadataObjectTarget;
    BOOL isMicGranted;//麦克风权限是否被允许
    
    CocoaSecurityResult *_result;
    BOOL _isRecordingCancel;
    AVAssetExportSession *_exportSession;
    BOOL flashMode;
    BOOL isUsedFlash;
}

@property (nonatomic,strong) AVCaptureMetadataOutput            *metadataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput              *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *audioMicInput;
@property (nonatomic, strong) AVCaptureDeviceFormat             *defaultFormat;
@property (nonatomic, strong) AVCaptureConnection               *audioConnection;
@property (nonatomic, strong) AVCaptureDevice                   *defaultVideoDevice;

@property (nonatomic, strong) AVCaptureVideoDataOutput          *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput          *movieFileOutput;

// For video data output
@property (nonatomic, strong) AVAssetWriter                     *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterAudioInput;

@property (nonatomic, strong) GPUImageMovie                     *alphaMovie;
@property (nonatomic, strong) GPUImageMovie                     *bodyMovie;
@property (nonatomic, strong) GPUImageMovieWriter               *movieWriter;
@property (nonatomic, strong) GPUImageChromaKeyBlendFilter      *filter;

@property (nonatomic, strong) AVMutableComposition              *composition;
@property (nonatomic, strong) NSMutableArray                    *passThroughTimeRanges;
@property (nonatomic, strong) NSMutableArray                    *transitionTimeRanges;
@property (nonatomic, strong) UIImagePickerController           *moviePicker;

@property (nonatomic, strong) DLYResource                       *resource;
@property (nonatomic, strong) DLYSession                        *session;

@property (nonatomic, strong) AVMutableVideoComposition         *videoComposition;
@property (nonatomic, strong) AVAssetExportSession              *assetExporter;

@property (atomic, assign)    BOOL                              isCapturing;//正在录制
@property (nonatomic, strong) NSMutableArray                    *imageArr;
@property (nonatomic, strong) NSTimer                           *recordTimer; //准备拍摄片段闪烁的计时器

@property (nonatomic, strong) NSString                          *currentDeviceType;

@property (retain, nonatomic) GPUImageMovie                     *movieFile;
@property (retain, nonatomic) GPUImageOutput<GPUImageInput>     *outputFilter;
@property (retain, nonatomic) GPUImageMovieWriter               *inputMovieWriter;

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
    _captureSession               = nil;
    _captureVideoPreviewLayer     = nil;
    _backCameraInput              = nil;
    _frontCameraInput             = nil;
    _audioOutput                  = nil;
    _videoOutput                  = nil;
    _audioConnection              = nil;
    _videoConnection              = nil;
}
#pragma mark - Lazy Load -

-(DLYResource *)resource{
    if (!_resource) {
        _resource = [[DLYResource alloc] init];
    }
    return _resource;
}

-(NSMutableArray *)imageArray{
    if (_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}
-(DLYMiniVlogPart *)currentPart{
    if (!_currentPart) {
        _currentPart = [[DLYMiniVlogPart alloc] init];
    }
    return _currentPart;
}
-(DLYSession *)session{
    if (!_session) {
        _session = [[DLYSession alloc] init];
    }
    return _session;
}
-(AVCaptureDevice *)defaultVideoDevice{
    
    if (!_defaultVideoDevice) {
        _defaultVideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _defaultVideoDevice;
}
#pragma mark - 视频录制相关访问权限检测 -
- (BOOL)checkCameraAuthorization {
    __block BOOL isAvalible = NO;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized: //授权
            isAvalible = YES;
            break;
        case AVAuthorizationStatusDenied:   //拒绝，弹框
        {
            isAvalible = NO;
        }
            break;
        case AVAuthorizationStatusNotDetermined:   //没有决定，第一次启动默认弹框
        {
            isAvalible = NO;
        }
            break;
        case AVAuthorizationStatusRestricted:  //受限制，家长控制器
            isAvalible = NO;
            break;
    }
    return isAvalible;
}
-(AVCaptureSession *)captureSession{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
        
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
    }
    return _captureSession;
}
- (instancetype)initWithPreviewView:(UIView *)previewView{
    if (self = [super init]) {
        
        [self createTimer];
        referenceOrientation = (AVCaptureVideoOrientation)UIDeviceOrientationPortrait;
        
        NSError *error;

        [self.captureSession beginConfiguration];
        self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
        [self.captureSession commitConfiguration];

        //添加后置摄像头的输入
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self.captureSession addInput:self.backCameraInput];
            _currentVideoDeviceInput = self.backCameraInput;
        }else{
            DLYLog(@"Back camera intput add faild");
        }
        
        //添加麦克风的输入
        if ([self.captureSession canAddInput:self.audioMicInput]) {
            [self.captureSession addInput:self.audioMicInput];
        }else{
            DLYLog(@"Mic input add faild");
        }
        
        if (error) {
            DLYLog(@"Video input creation failed");
            return nil;
        }
        
        // save the default format
//        self.defaultFormat = self.currentVideoDeviceInput.device.activeFormat;
        self.defaultFormat = self.videoDevice.activeFormat;
        defaultVideoMaxFrameDuration = self.videoDevice.activeVideoMaxFrameDuration;
        
        
        if (previewView) {
            self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
            self.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
            self.captureVideoPreviewLayer.frame = previewView.bounds;
            self.captureVideoPreviewLayer.contentsGravity = kCAGravityTopLeft;
            self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [previewView.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
        }
        
        //添加视频输出
        if ([self.captureSession canAddOutput:self.videoOutput]) {
            [self.captureSession addOutput:self.videoOutput];
        }else{
            DLYLog(@"Video output creation faild");
        }
        //添加元数据输出
        if ([self.captureSession canAddOutput:self.metadataOutput]) {
            [self.captureSession addOutput:self.metadataOutput];
            self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
        }
        
        //添加音频输出
        if ([self.captureSession canAddOutput:self.audioOutput]) {
            [self.captureSession addOutput:self.audioOutput];
        }else{
            DLYLog(@"Audio output creation faild");
        }
        
        //According to the previewlayer center focus after launch
//        CGPoint point = self.captureVideoPreviewLayer.center;
        CGPoint point = CGPointMake(self.captureVideoPreviewLayer.preferredFrameSize.width, self.captureVideoPreviewLayer.preferredFrameSize.height);
        CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
        [self focusWithMode:AVCaptureFocusModeAutoFocus atPoint:cameraPoint];
        
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
        
        self.metadataOutput.rectOfInterest = [self.captureVideoPreviewLayer metadataOutputRectOfInterestForRect:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        
        [self.captureSession startRunning];
    }
    return self;
}
#pragma mark - 补光灯开关 -
- (void) switchFlashMode:(BOOL)isOn
{
    isUsedFlash = YES;
    flashMode = isOn;
    AVCaptureDevice *device = self.defaultVideoDevice;
    if ([device hasTorch]) {
        
        if (isOn) {
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOn];
            [device unlockForConfiguration];
        }else{
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
}
#pragma mark - 切换摄像头 -
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    
    if (isFront) {
        
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.backCameraInput];
        
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.frontCameraInput];//切换成了前置
            self.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
    }else {
        
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.backCameraInput];//切换成了后置
        }
    }
    [self.captureSession startRunning];
}
#pragma mark - Recorder初始化相关懒加载 -
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
        dispatch_queue_t videoCaptureQueue = dispatch_queue_create("videocapture", DISPATCH_QUEUE_SERIAL);
        [_videoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    }
    return _videoOutput;
}
-(AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        dispatch_queue_t metadataOutputQueue = dispatch_queue_create("metadataOutput", DISPATCH_QUEUE_SERIAL);
        [_metadataOutput setMetadataObjectsDelegate:self queue:metadataOutputQueue];
    }
    return _metadataOutput;
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
            DLYLog(@"device.activeFormat:%@", device.activeFormat);
            return device;
        }
    }
    return nil;
}
//摄像头切换翻转动画
- (void)changeCameraAnimation {
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.3;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromTop;
    [self.captureVideoPreviewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}
- (void)animationDidStart:(CAAnimation *)anim {
    [self.captureSession startRunning];
}

- (void)updateOrientationWithPreviewView:(UIView *)previewView {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    // Don't update the reference orientation when the device orientation is face up/down or unknown.
    if (UIDeviceOrientationIsLandscape(orientation)) {
        referenceOrientation = (AVCaptureVideoOrientation)orientation;
    }
    
    [[self.captureVideoPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
    
    readyToRecordVideo = NO;
}
#pragma mark - 点触设置曝光 -

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY);
};

- (void)focusOnceWithPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = _currentVideoDeviceInput.device;
    
    if ([captureDevice lockForConfiguration:nil]) {
        
        // 设置对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeLocked]) {
            [captureDevice setFocusMode:AVCaptureFocusModeLocked];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        
        // 设置曝光
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [captureDevice setExposureMode:AVCaptureExposureModeLocked];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
        
        //设置白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
        }
        [captureDevice unlockForConfiguration];
    }
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = _currentVideoDeviceInput.device;
    
    if ([captureDevice lockForConfiguration:nil]) {
        
        // 设置对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        
        // 设置曝光
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
        
        //设置白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [captureDevice unlockForConfiguration];
        
        NSLog(@"Current point of the capture device is :x = %f,y = %f",point.x,point.y);
    }
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
                                               [NSNumber numberWithInteger:bitsPerSecond],AVVideoAverageBitRateKey,/*
                                                                                                                    [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,*/
                                               nil], AVVideoCompressionPropertiesKey,
                                              nil];
    
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
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
            if (self.assetWriter.error) {
                DLYLog(@"AVAssetWriter startWriting error:%@", self.assetWriter.error);
            }
        }
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        
        if (mediaType == AVMediaTypeVideo) {
            
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                
                if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                    
                    DLYLog(@"isRecording:%d, willBeStarted:%d", self.isRecording, recordingWillBeStarted);
                    if (self.assetWriter.error) {
                        DLYLog(@"AVAssetWriterInput video appendSampleBuffer error:%@", self.assetWriter.error);
                    }
                }
            }
        }
        else if (mediaType == AVMediaTypeAudio) {
            
            if (self.assetWriterAudioInput.readyForMoreMediaData) {
                
                if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                    if (self.assetWriter.error) {
                        DLYLog(@"AVAssetWriterInput audio appendSapleBuffer error:%@", self.assetWriter.error);
                    }
                }
            }
        }
    }
}

#pragma mark - Public

//- (void)resetFormat {
//
//    BOOL isRunning = self.captureSession.isRunning;
//
//    if (isRunning) {
//        [self.captureSession stopRunning];
//    }
//
//    [self.defaultVideoDevice lockForConfiguration:nil];
//    self.defaultVideoDevice.activeFormat = self.defaultFormat;
//    self.defaultVideoDevice.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
//    [self.defaultVideoDevice unlockForConfiguration];
//
//    if (isRunning) {
//        [self.captureSession startRunning];
//    }
//}

#pragma mark - 改变录制帧率 -
- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    BOOL isRunning = self.captureSession.isRunning;
    if (isRunning)  [self.captureSession stopRunning];
    
    AVCaptureDevice *device = self.defaultVideoDevice;
    if (isUsedFlash){
        isUsedFlash = NO;
        if (flashMode) {
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOn];
            [device unlockForConfiguration];
        }else{
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
    
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [device formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= desiredFPS && desiredFPS <= range.maxFrameRate && width >= maxWidth) {
                DLYLog(@"最终设定的最佳帧率: %f",desiredFPS);
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    
    if (selectedFormat)
    {
        DLYLog(@"selected format:%@", selectedFormat);
        if ([device lockForConfiguration:nil]) {
            
            device.activeFormat = selectedFormat;
            device.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);//设置帧率
            device.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [device unlockForConfiguration];
        }
    }
    
    [self.captureSession beginConfiguration];
    self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    [self.captureSession commitConfiguration];
    
    if (isRunning) [self.captureSession startRunning];
}
#pragma mark - 开始录制 -
- (void)startRecordingWithPart:(DLYMiniVlogPart *)part {
    
    _currentPart = part;
    
    if (_currentPart.recordType == DLYMiniVlogRecordTypeSlomo) {
        DLYLog(@"🎬🎬🎬 慢镜头片段");
        [self switchFormatWithDesiredFPS:120.0];
        
    }else if (_currentPart.recordType == DLYMiniVlogRecordTypeTimelapse){
        DLYLog(@"🎬🎬🎬 快镜头片段");
        [self switchFormatWithDesiredFPS:50.0];
    }else{
        DLYLog(@"🎬🎬🎬 正常拍摄片段");
        [self switchFormatWithDesiredFPS:50.0];
    }
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    // Don't update the reference orientation when the device orientation is face up/down or unknown.
    if (UIDeviceOrientationIsLandscape(orientation)) {
        referenceOrientation = (AVCaptureVideoOrientation)orientation;
    }
    
    NSString *_outputPath =  [self.resource getSaveDraftPartWithPartNum:_currentPart.partNum];
    if (_outputPath) {
        _currentPart.partUrl = [NSURL fileURLWithPath:_outputPath];
        DLYLog(@"第 %lu 个片段的地址 :%@",_currentPart.partNum + 1,_currentPart.partUrl);
    }else{
        DLYLog(@"片段地址获取为空");
    }
    
    NSError *error;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:_currentPart.partUrl fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        DLYLog(@"AVAssetWriter error:%@", error);
    }
    
    recordingWillBeStarted = YES;
}
#pragma mark - 停止录制 -
- (void)stopRecording {
    
    DLYLog(@"停止录制");
    dispatch_async(movieWritingQueue, ^{
        
        _isRecording = NO;
        readyToRecordVideo = NO;
        readyToRecordAudio = NO;
        
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            self.assetWriterVideoInput = nil;
            self.assetWriterAudioInput = nil;
            self.assetWriter = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self saveRecordedFile];
            });
        }];
    });
}
#pragma mark - 取消录制 -
- (void)cancelRecording{
    
    DLYLog(@"取消录制");
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
- (void) restartRecording{
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}
#pragma mark - 暂停录制 -
- (void) pauseRecording{
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}
#pragma mark - 视频速度处理 -

// 处理速度视频
- (void)setSpeedWithVideo:(NSURL *)videoPartUrl outputUrl:(NSURL *)outputUrl BGMVolume:(float)BGMVolume recordTypeOfPart:(DLYMiniVlogRecordType)recordType completed:(void(^)())completed {
    
//    NSLog(@"video set thread: %@", [NSThread currentThread]);
    NSLog(@"🚀...🚀...调节视频速度...");
    // 获取视频
    if (!videoPartUrl) {
        DLYLog(@"待调速的视频片段不存在!");
        return;
    }else{
        
        // 适配视频速度比率
        CGFloat scale = 0;
        if(recordType == DLYMiniVlogRecordTypeTimelapse){
            scale = 0.2f;  // 0.2对应  快速 x5   播放时间压缩帧率平均(低帧率)
        } else if (recordType == DLYMiniVlogRecordTypeSlomo) {
            scale = 3.0f;  // 慢速 x3   播放时间拉长帧率平均(高帧率)
        }else{
            scale = 1.0f;
        }
        AVURLAsset *videoAsset = nil;
        if(videoPartUrl) {
            videoAsset = [[AVURLAsset alloc]initWithURL:videoPartUrl options:nil];
        }
        
        // 视频组合
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        // 视频轨道
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        if (BGMVolume < 50) {
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL isSuccess = [fileManager moveItemAtURL:videoPartUrl toURL:outputUrl error:&error];
            DLYLog(@"%@",isSuccess ? @"移动不需要调速的视频片段成功":@"移动不需要调速的频段片段失败");
            if (_currentPart.partNum != 0 && _currentPart.partNum != self.session.currentTemplate.parts.count - 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
                });
            }
            // 音频轨道
            AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            // 插入视频轨道
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
            // 插入音频轨道
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
            
        }else if (BGMVolume == 100){//不录音的片段做丢弃原始音频处理
            
            // 插入视频轨道
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
            
            // 根据速度比率调节音频和视频
            [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) toDuration:CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale)];
        }
        // 配置导出
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
        
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = outputUrl;
        assetExport.shouldOptimizeForNetworkUse = YES;
        // 导出视频
        [assetExport exportAsynchronouslyWithCompletionHandler:^{
            completed();
        }];
    }
}

- (void)addVideoEffectsWithUrl:(NSURL *) inputUrl recordType:(DLYMiniVlogRecordType)recordType andBGMVolume:(float)BGMVolume {
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    if (_currentPart.partNum != 0 && _currentPart.partNum != template.parts.count - 1) {
        return;
    }
    
    BOOL isAudio;
    if (recordType == DLYMiniVlogRecordTypeNormal) {
        if (BGMVolume < 50) {
            isAudio = YES;
        }else {
            isAudio = NO;
        }
    }else {
        isAudio = NO;
    }
    if (_currentPart.partNum == 0) {
        NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
        NSArray *headArr = [[DLYThemesData sharedInstance] getHeadImageArray];
        NSMutableArray *headArray = [NSMutableArray arrayWithArray:headArr];
        [self buildVideoEffectsToMP4:headerPath inputVideoURL:inputUrl andImageArray:headArray andBeginTime:0.1 isAudio:isAudio callback:^(NSURL *finalUrl, NSString *filePath) {
            NSLog(@"片头完成");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
            });
        }];
    }else {
        NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
        NSArray *footArr = [[DLYThemesData sharedInstance] getFootImageArray];
        NSMutableArray *footArray = [NSMutableArray arrayWithArray:footArr];
        [self buildVideoEffectsToMP4:footerPath inputVideoURL:inputUrl andImageArray:footArray andBeginTime:0.1 isAudio:isAudio callback:^(NSURL *finalUrl, NSString *filePath) {
            NSLog(@"片尾完成");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
            });
        }];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
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
#pragma mark 从输出的元数据中捕捉人脸

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    //检测到目标元数据
    if (metadataObjects.count) {
        isDetectedMetadataObjectTarget = YES;
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        
//        DLYLog(@"检测到 %lu 个人脸",metadataObjects.count);
        //取到识别到的人脸区域
        AVMetadataObject *transformedMetadataObject = [self.captureVideoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        faceRegion = transformedMetadataObject.bounds;
        
        //检测到人脸
        if (metadataObject.type == AVMetadataObjectTypeFace) {
            //检测区域
            CGRect referenceRect = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            //            DLYLog(@"%d, facePathRect: %@, faceRegion: %@",CGRectContainsRect(referenceRect, faceRegion) ? @"包含人脸":@"不包含人脸",NSStringFromCGRect(referenceRect),NSStringFromCGRect(faceRegion));
        }else{
            faceRegion = CGRectZero;
        }
    }else{
        isDetectedMetadataObjectTarget = NO;
        faceRegion = CGRectZero;
    }
}
NSInteger timeCount = 0;
NSInteger maskCount = 0;
NSInteger startCount = MAXFLOAT;
BOOL isOnce = YES;

- (void)createTimer{
    //获得队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //创建一个定时器
    dispatch_source_t enliveTime = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //设置开始时间
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    //设置时间间隔
    uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC);
    //设置定时器
    dispatch_source_set_timer(enliveTime, start, interval, 0);
    //设置回调
    dispatch_source_set_event_handler(enliveTime, ^{
        
        CGFloat distance = distanceBetweenPoints(faceRegion.origin, lastFaceRegion.origin);
        lastFaceRegion = faceRegion;
        if (distance < 20) {
            if (isOnce) {
                isOnce = NO;
                CGPoint point = CGPointMake(faceRegion.size.width/2, faceRegion.size.height/2);
                CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
                [self focusOnceWithPoint:cameraPoint];
                startCount = timeCount;
            }
            maskCount++;
        }
        timeCount++;
        if (timeCount - startCount >= 3) {
            if (maskCount == 3) {
                faceRegion = CGRectZero;
            }
            isOnce = YES;
            startCount = MAXFLOAT;
            maskCount = 0;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(displayRefrenceRect:)]) {
                [self.delegate displayRefrenceRect:faceRegion];
            }
        });
        if(timeCount > MAXFLOAT){
            dispatch_cancel(enliveTime);
        }
        
    });
    //启动定时器
    dispatch_resume(enliveTime);
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
- (void) saveRecordedFile
{
    NSString *exportPath;
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            exportPath = [NSString stringWithFormat:@"%@/part%lu.mp4",draftPath,(long)_currentPart.partNum];
        }
    }
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DLYIndicatorView sharedIndicatorView] startFlashAnimatingWithTitle:@"片段处理中..."];
        typeof(self) weakSelf = self;
        [weakSelf setSpeedWithVideo:_currentPart.partUrl outputUrl:exportUrl BGMVolume:_currentPart.BGMVolume recordTypeOfPart:_currentPart.recordType completed:^{
            
            //添加片头片尾
            [self addVideoEffectsWithUrl:exportUrl recordType:_currentPart.recordType andBGMVolume:_currentPart.BGMVolume];
            DLYLog(@"第 %lu 个片段调速完成",self.currentPart.partNum + 1);
            [self.resource removePartWithPartNumFormCache:self.currentPart.partNum];
            if (_currentPart.partNum != 0 && _currentPart.partNum != self.session.currentTemplate.parts.count - 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
                });
            }
        }];
    });
}

#pragma mark - 合并 -
- (void) mergeVideoWithVideoTitle:(NSString *)videoTitle SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    NSMutableArray *videoArray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            for (NSInteger i = 0; i < [draftArray count]; i++) {
                NSString *path = draftArray[i];
                DLYLog(@"🔄🔄🔄合并-->加载--> 第 %lu 个片段",i);
                if ([path hasSuffix:@"mp4"]) {
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    [videoArray addObject:url];
                }
            }
        }
    }
    DLYLog(@"待合成的视频片段: %@",videoArray);
    
    for (NSUInteger i = 0; i < videoArray.count; i++) {

        AVURLAsset *asset = nil;
        if (i == 0) {
            NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                NSURL *headerUrl = [NSURL fileURLWithPath:headerPath];
                asset = [AVURLAsset URLAssetWithURL:headerUrl options:nil];
            }else {
                asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
            }
        }else if (i == videoArray.count - 1) {
            NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:footerPath]) {
                NSURL *footerUrl = [NSURL fileURLWithPath:footerPath];
                asset = [AVURLAsset URLAssetWithURL:footerUrl options:nil];
            }else {
                asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
            }
        }else {
            asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
        }
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        
        CMTime cursorTime = kCMTimeZero;
        
        if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero,asset.duration);
        
        NSError *videoError = nil;
        [compositionVideoTrack insertTimeRange:timeRange ofTrack:assetVideoTrack atTime:cursorTime error:&videoError];
        if (videoError) {
            DLYLog(@"视频合成过程中视频轨道插入发生错误,错误信息 :%@",videoError);
        }
        
        NSError *audioError = nil;
        [compositionAudioTrack insertTimeRange:timeRange ofTrack:assetAudioTrack atTime:cursorTime error:&audioError];
        if (audioError) {
            DLYLog(@"视频合成过程音频轨道插入发生错误,错误信息 :%@",audioError);
        }
        
        cursorTime = CMTimeAdd(cursorTime, timeRange.duration);
    }
    
    NSURL *productOutputUrl = nil;
    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        _result = [CocoaSecurity md5:[[NSDate date] description]];
        NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",productPath,_result.hex];
        if (outputPath) {
            productOutputUrl = [NSURL fileURLWithPath:outputPath];
        }else{
            DLYLog(@"❌❌❌合并视频保存地址获取失败 !");
        }
    }
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1280x720];
    assetExportSession.outputURL = productOutputUrl;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"⛳️⛳️⛳️全部片段merge成功");
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@"m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        [self addMusicToVideo:productOutputUrl audioUrl:BGMUrl videoTitle:videoTitle successBlock:successBlock failure:failureBlcok];
    }];
}

#pragma mark - 转场 -
- (void) addTransitionEffectWithTitle:(NSString *)videoTitle  successBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    self.composition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *compositionVideoTrackA = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *compositionVideoTrackB = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    
    AVMutableCompositionTrack *compositionAudioTrackA = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    AVMutableCompositionTrack *compositionAudioTrackB = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    NSArray *videoTracks = @[compositionVideoTrackA, compositionVideoTrackB];
    NSArray *audioTracks = @[compositionAudioTrackA, compositionAudioTrackB];
    
    NSMutableArray *videoArray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            for (NSInteger i = 0; i < [draftArray count]; i++) {
                NSString *path = draftArray[i];
                DLYLog(@"🔄🔄🔄合并-->加载--> 第 %lu 个片段",i);
                if ([path hasSuffix:@"mp4"]) {
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    [videoArray addObject:url];
                }
            }
        }
    }
    DLYLog(@"待合成的视频片段: %@",videoArray);
    
    for (NSUInteger i = 0; i < videoArray.count; i++) {
        
        AVURLAsset *asset = nil;
        if (i == 0) {
            NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                NSURL *headerUrl = [NSURL fileURLWithPath:headerPath];
                asset = [AVURLAsset URLAssetWithURL:headerUrl options:nil];
            }else {
                asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
            }
        }else if (i == videoArray.count - 1) {
            NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:footerPath]) {
                NSURL *footerUrl = [NSURL fileURLWithPath:footerPath];
                asset = [AVURLAsset URLAssetWithURL:footerUrl options:nil];
            }else {
                asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
            }
        }else {
            asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
        }
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        
        CMTime videoCursorTime = kCMTimeZero;
        CMTime audioCursorTime = kCMTimeZero;
        CMTime transitionDuration = CMTimeMake(1, 5);
        
        if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        NSUInteger trackIndex = i % 2;
        AVMutableCompositionTrack *currentVideoTrack = videoTracks[trackIndex];
        AVMutableCompositionTrack *currentAudioTrack = audioTracks[trackIndex];
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, assetVideoTrack.timeRange.duration);
        
        BOOL isInsertVideoSuccess = [currentVideoTrack insertTimeRange:timeRange
                                                          ofTrack:assetVideoTrack
                                                           atTime:videoCursorTime error:nil];
        if (isInsertVideoSuccess == NO) {
            DLYLog(@"合并时插入图像轨失败");
        }
        
        BOOL isInsertAudioSuccess = [currentAudioTrack insertTimeRange:timeRange
                                                                   ofTrack:assetAudioTrack
                                                                    atTime:videoCursorTime error:nil];
        if (isInsertAudioSuccess == NO) {
            DLYLog(@"合并时插入音轨失败");
        }
        
        videoCursorTime = CMTimeAdd(videoCursorTime, timeRange.duration);
        videoCursorTime = CMTimeSubtract(videoCursorTime, transitionDuration);
        audioCursorTime = CMTimeAdd(audioCursorTime, timeRange.duration);
        
        if (i + 1 < videoArray.count) {
            timeRange = CMTimeRangeMake(videoCursorTime, transitionDuration);
            NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            [self.transitionTimeRanges addObject:timeRangeValue];
        }
    }
    
    AVVideoComposition *videoComposition = [self buildVideoComposition];
    
    NSURL *productOutputUrl = nil;
    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        _result = [CocoaSecurity md5:[[NSDate date] description]];
        NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",productPath,_result.hex];
        if (outputPath) {
            productOutputUrl = [NSURL fileURLWithPath:outputPath];
        }else{
            DLYLog(@"❌❌❌合并视频保存地址获取失败 !");
        }
    }
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPreset1280x720];
    assetExportSession.videoComposition = videoComposition;
    assetExportSession.outputURL = productOutputUrl;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"⛳️⛳️⛳️全部片段merge成功");
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@"m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        [self addMusicToVideo:productOutputUrl audioUrl:BGMUrl videoTitle:videoTitle successBlock:successBlock failure:failureBlcok];
    }];
}
- (AVVideoComposition *)buildVideoComposition {
    
    AVVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.composition];
    
    NSArray *transitionInstructions = [self transitionInstructionsInVideoComposition:videoComposition];
    
    for (DLYTransitionInstructions *instructions in transitionInstructions) {
        
        CMTimeRange timeRange = instructions.compositionInstruction.timeRange;
        
        AVMutableVideoCompositionLayerInstruction *fromLayer = instructions.fromLayerInstruction;
        
        AVMutableVideoCompositionLayerInstruction *toLayer = instructions.toLayerInstruction;
        
        CGAffineTransform identityTransform = CGAffineTransformIdentity;
        
        CGFloat videoWidth = videoComposition.renderSize.width;
        CGFloat videoHeight = videoComposition.renderSize.height;
        NSLog(@"videoWidth: %f,videoHeight: %f",videoWidth,videoHeight);
        //Transform
        CGAffineTransform fromDestTransform = CGAffineTransformMakeTranslation(-videoWidth, 0.0);
        CGAffineTransform toStartTransform = CGAffineTransformMakeTranslation(videoWidth, 0.0);
        
        CGAffineTransform transform1 = CGAffineTransformMakeRotation(M_PI);
        CGAffineTransform transform2 = CGAffineTransformScale(transform1, 2.0, 2.0);
        
        //Rotation
        CGAffineTransform fromDestTransformRotation = CGAffineTransformMakeRotation(-M_PI);
        CGAffineTransform toStartTransformRotation = CGAffineTransformMakeRotation(M_PI);
        
        //缩放
        CGAffineTransform fromTransformScale = CGAffineTransformMakeScale(2, 2);
        CGAffineTransform toTransformScale = CGAffineTransformMakeScale(2, 2);
        
        DLYVideoTransitionType type = instructions.transition.type;
        
        switch (type) {
            case DLYVideoTransitionTypeDissolve:
                
                [fromLayer setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:timeRange];
                break;
            case DLYVideoTransitionTypePush:
                
                [fromLayer setTransformRampFromStartTransform:identityTransform
                                               toEndTransform:fromDestTransform
                                                    timeRange:timeRange];
                
                [toLayer setTransformRampFromStartTransform:toStartTransform
                                             toEndTransform:identityTransform
                                                  timeRange:timeRange];
                break;
            case DLYVideoTransitionTypeWipe:
                
                [fromLayer setTransformRampFromStartTransform:identityTransform
                                               toEndTransform:transform2
                                                    timeRange:timeRange];
                
                [toLayer setTransformRampFromStartTransform:transform2
                                             toEndTransform:identityTransform
                                                  timeRange:timeRange];
                break;
            case DLYVideoTransitionTypeClockwiseRotate:
                
                [fromLayer setTransformRampFromStartTransform:identityTransform
                                               toEndTransform:fromDestTransformRotation
                                                    timeRange:timeRange];
                
                [toLayer setTransformRampFromStartTransform:toStartTransformRotation
                                             toEndTransform:identityTransform
                                                  timeRange:timeRange];
                break;
            case DLYVideoTransitionTypeZoom:
                
                [fromLayer setTransformRampFromStartTransform:identityTransform toEndTransform:fromTransformScale timeRange:timeRange];
                [toLayer setTransformRampFromStartTransform:identityTransform toEndTransform:toTransformScale timeRange:timeRange];
                
                break;
                
            default:
                break;
        }
        
        instructions.compositionInstruction.layerInstructions = @[fromLayer,toLayer];
    }
    return videoComposition;
}
- (NSArray *)transitionInstructionsInVideoComposition:(AVVideoComposition *)vc {
    
    NSMutableArray *transitionInstructions = [NSMutableArray array];
    
    int layerInstructionIndex = 1;
    
    NSArray *compositionInstructions = vc.instructions;
    
    for (AVMutableVideoCompositionInstruction *vci in compositionInstructions) {
        
        if (vci.layerInstructions.count == 2) {
            
            DLYTransitionInstructions *instructions = [[DLYTransitionInstructions alloc] init];
            
            instructions.compositionInstruction = vci;
            
            instructions.fromLayerInstruction =
            (AVMutableVideoCompositionLayerInstruction *)vci.layerInstructions[1 - layerInstructionIndex];
            
            instructions.toLayerInstruction =
            (AVMutableVideoCompositionLayerInstruction *)vci.layerInstructions[layerInstructionIndex];
            
            [transitionInstructions addObject:instructions];
            
            layerInstructionIndex = layerInstructionIndex == 1 ? 0 : 1;
        }
    }
    
    for (NSUInteger i = 0; i < transitionInstructions.count; i++) {
        
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        DLYMiniVlogPart *part = template.parts[i];
        DLYVideoTransitionType transitionType = part.transitionType;
        
        DLYTransitionInstructions *tis = transitionInstructions[i];
        
        DLYVideoTransition *transition = [DLYVideoTransition videoTransition];
        
        if (transitionType == DLYVideoTransitionTypeNone) {
            
        }else{
            transition.type = transitionType;
            tis.transition = transition;
        }
    }
    return transitionInstructions;
}
#pragma mark - 配音 -
- (void) addMusicToVideo:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl videoTitle:(NSString *)videoTitle successBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioUrl options:nil];
    
    AVAssetTrack *videoAssetTrack = nil;
    AVAssetTrack *audioAssetTrack = nil;
    
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    CMTime cursorTime = kCMTimeZero;
    NSError *error = nil;
    if (videoAssetTrack) {
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:cursorTime error:&error];
    }
    if (audioAssetTrack) {
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:cursorTime error:&error];
    }
    
    [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
    
    //添加标题
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    if ([[mixComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        // build a pass through video composition
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        mutableVideoComposition.renderSize = videoAssetTrack.naturalSize;
        
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
        
        AVAssetTrack *videoTrack = [mixComposition tracksWithMediaType:AVMediaTypeVideo][0];
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        passThroughInstruction.layerInstructions = @[passThroughLayer];
        mutableVideoComposition.instructions = @[passThroughInstruction];
        
        CGSize renderSize = mutableVideoComposition.renderSize;
        CALayer *videoTitleLayer = [self addTitleForVideoWith:videoTitle size:renderSize];
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
        videoLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        
        videoTitleLayer.position = CGPointMake(mutableVideoComposition.renderSize.width / 2, mutableVideoComposition.renderSize.height / 2);
        [parentLayer addSublayer:videoTitleLayer];
        
        if (APPTEST) {
            CALayer *watermarkLayer = [CALayer layer];
            watermarkLayer = [self addWatermarkWithSize:renderSize];
            watermarkLayer.position = CGPointMake(mutableVideoComposition.renderSize.width - 358, 8);
            [parentLayer addSublayer:watermarkLayer];
        }
        
        mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    
    //处理视频原声
    AVAssetTrack *originalAudioAssetTrack = nil;
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        originalAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    AVMutableCompositionTrack *originalAudioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *videoParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:originalAudioCompositionTrack];
    AVMutableAudioMixInputParameters *BGMParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
    
    NSArray *partArray = self.session.currentTemplate.parts;
    
    for (NSInteger i = 0; i < partArray.count; i++) {
        
        DLYMiniVlogPart *part = partArray[i];
        
        NSArray *startArr = [part.dubStartTime componentsSeparatedByString:@":"];
        NSString *startTimeStr = startArr[1];
        float startTime = [startTimeStr floatValue];
        _startTime = CMTimeMake(startTime, 1);
        
        NSArray *stopArr = [part.dubStopTime componentsSeparatedByString:@":"];
        NSString *stopTimeStr = stopArr[1];
        float stopTime = [stopTimeStr floatValue];
        _stopTime = CMTimeMake(stopTime, 1);
        
        //时长小于1s的片段音轨切换平滑特殊处理
        float rampOffsetValue = 1;
        
        _prePoint = CMTimeMake(stopTime - rampOffsetValue, 1);
        CMTime duration = CMTimeSubtract(_stopTime, _prePoint);
        
        CMTimeRange timeRange = CMTimeRangeMake(_startTime, duration);
        CMTimeRange preTimeRange = CMTimeRangeMake(_prePoint, CMTimeMake(2, 1));
        
        if (part.BGMVolume == 100) {//空镜
            [BGMParameters setVolumeRampFromStartVolume:part.BGMVolume / 100 toEndVolume:part.BGMVolume / 100 timeRange:timeRange];
//            [BGMParameters setVolumeRampFromStartVolume:5.0 toEndVolume:0.4 timeRange:preTimeRange];
            
            [videoParameters setVolumeRampFromStartVolume:0 toEndVolume:0 timeRange:timeRange];
        }else if(part.BGMVolume < 50){//人声
            [videoParameters setVolumeRampFromStartVolume:2.0 toEndVolume:2.0 timeRange:timeRange];
            [BGMParameters setVolumeRampFromStartVolume:part.BGMVolume / 100 toEndVolume:part.BGMVolume / 100 timeRange:timeRange];
//            [BGMParameters setVolumeRampFromStartVolume:0.4 toEndVolume:5.0 timeRange:preTimeRange];
        }
    }
    audioMix.inputParameters = @[videoParameters,BGMParameters];
    
    NSURL *outPutUrl = [self.resource saveProductToSandbox];
    self.currentProductUrl = outPutUrl;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.currentProductUrl.absoluteString])
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.currentProductUrl.absoluteString error:nil];
    }
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
    assetExportSession.outputURL = outPutUrl;
    assetExportSession.audioMix = audioMix;
    assetExportSession.videoComposition = mutableVideoComposition;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExportSession status]) {
            case AVAssetExportSessionStatusFailed:{
                DLYLog(@"配音失败: %@",[[assetExportSession error] description]);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                if ([self.delegate  respondsToSelector:@selector(didFinishEdititProductUrl:)]) {
                    [self.delegate didFinishEdititProductUrl:outPutUrl];
                }
                ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
                [assetLibrary saveVideo:outPutUrl toAlbum:@"一分" completionBlock:^(NSURL *assetURL, NSError *error) {
                    DLYLog(@"⛳️⛳️⛳️配音完成后保存在手机相册");
                    BOOL isSuccess = NO;
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    
                    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
                    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
                        
                        NSString *targetPath = [productPath stringByAppendingFormat:@"/%@.mp4",_result.hex];
                        isSuccess = [fileManager removeItemAtPath:targetPath error:nil];
                        DLYLog(@"%@",isSuccess ? @"⛳️⛳️⛳️成功删除未配音的成片视频 !" : @"❌❌❌删除未配音视频失败");
                    }
                    NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
//                        isSuccess = [fileManager removeItemAtPath:headerPath error:nil];
//                        DLYLog(@"删除片头");
                    }
                    NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:footerPath]) {
//                        isSuccess = [fileManager removeItemAtPath:footerPath error:nil];
//                        DLYLog(@"删除片尾");
                    }
                    successBlock();

                } failureBlock:^(NSError *error) {
                    failureBlcok(error);
                }];
            }break;
            default:
                break;
        }
    }];
}
#pragma mark - 添加测试水印 -
- (CALayer *) addWatermarkWithSize:(CGSize)renderSize
{
    CALayer *overlayLayer = [CALayer layer];
    CATextLayer *watermarkLayer = [CATextLayer layer];
    UIFont *font = [UIFont systemFontOfSize:24.0];
    
    //获取当前时间
    NSString *currentTime  = [self getCurrentTime];
    //获取当前版本号
    NSDictionary*infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *localVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    //获取当前build号
    NSString *buildVersion = [infoDic objectForKey:@"CFBundleVersion"];
    //获取系统版本
    NSString *currentSystemVersion = [[UIDevice currentDevice] systemVersion];
    //获取机型
    DLYMobileDevice *mobileDevice = [DLYMobileDevice sharedDevice];
    _currentDeviceType = [mobileDevice iPhoneModel];
    
    NSString *watermarkMessage = [self.session.currentTemplate.templateTitle stringByAppendingFormat:@"   %@  %@  %@(%@)   %@",_currentDeviceType,currentSystemVersion,localVersion,buildVersion,currentTime];
    
    [watermarkLayer setFontSize:24.f];
    [watermarkLayer setFont:@"ArialRoundedMTBold"];
    [watermarkLayer setString:watermarkMessage];
    [watermarkLayer setAlignmentMode:kCAAlignmentCenter];
    [watermarkLayer setForegroundColor:[[UIColor colorWithHexString:@"FFFFFF" withAlpha:1] CGColor]];
    [watermarkLayer setBackgroundColor:[[UIColor colorWithHexString:@"#000000" withAlpha:0.8] CGColor]];
    watermarkLayer.contentsCenter = overlayLayer.contentsCenter;
    CGSize textSize = [watermarkMessage sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    watermarkLayer.bounds = CGRectMake(0, 0, textSize.width + 60, textSize.height + 25);
    
    [overlayLayer addSublayer:watermarkLayer];
    return overlayLayer;
}
#pragma mark - 视频标题设置 -
- (CALayer *) addTitleForVideoWith:(NSString *)titleText size:(CGSize)renderSize{
    
    CALayer *overlayLayer = [CALayer layer];
    CATextLayer *titleLayer = [CATextLayer layer];
    UIFont *font = [UIFont systemFontOfSize:68.0];
    
    [titleLayer setFontSize:68.f];
    [titleLayer setFont:@"LingWaiSCMedium"];//HanziPenTCRegular/LingWaiSC
    [titleLayer setString:titleText];
    [titleLayer setAlignmentMode:kCAAlignmentCenter];
    [titleLayer setForegroundColor:[[UIColor colorWithHexString:@"#FFD700" withAlpha:0.8] CGColor]];
    titleLayer.contentsCenter = overlayLayer.contentsCenter;
    CGSize textSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    titleLayer.bounds = CGRectMake(0, 0, textSize.width + 50, textSize.height + 25);
    
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    NSDictionary *subTitleDic = template.subTitle1;
    NSString *subTitleStart = [subTitleDic objectForKey:@"startTime"];
    NSString *subTitleStop = [subTitleDic objectForKey:@"stopTime"];
    
    float _subTitleStart = [self switchTimeWithTemplateString:subTitleStart] / 1000;
    float _subTitleStop = [self switchTimeWithTemplateString:subTitleStop] / 1000;
    float duration = _subTitleStop - _subTitleStart;
    
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation1.fromValue = [NSNumber numberWithFloat:0.0f];
    animation1.toValue = [NSNumber numberWithFloat:0.0f];
    animation1.repeatCount = 0;
    animation1.duration = _subTitleStart;
    [animation1 setRemovedOnCompletion:NO];
    [animation1 setFillMode:kCAFillModeForwards];
    animation1.beginTime = AVCoreAnimationBeginTimeAtZero;
    [titleLayer addAnimation:animation1 forKey:@"opacityAniamtion"];
    
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation2.fromValue = [NSNumber numberWithFloat:1.0f];
    animation2.toValue = [NSNumber numberWithFloat:0.0f];
    animation2.repeatCount = 0;
    animation2.duration = duration;
    [animation2 setRemovedOnCompletion:NO];
    [animation2 setFillMode:kCAFillModeForwards];
    animation2.beginTime = _subTitleStart;
    [titleLayer addAnimation:animation2 forKey:@"opacityAniamtion1"];
    
    [overlayLayer addSublayer:titleLayer];
    
    return overlayLayer;
}
#pragma mark - 视频叠加 -
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
    
    NSURL *outputUrl = [self.resource saveToSandboxFolderType:NSDocumentDirectory subfolderName:@"HeaderVideos" suffixType:@".mp4"];
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
#pragma mark - 媒体文件截取 -
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
    
    AVMutableVideoCompositionInstruction *videoCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [videoCompositionIns setTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssertTrack.timeRange.duration)];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoCompositionIns];
    videoComposition.renderSize = CGSizeMake(videoAssertTrack.naturalSize.height,videoAssertTrack.naturalSize.width);
    
    videoComposition.frameDuration = CMTimeMake(1, 60);
    
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssertTrack];
    [layerInst setTransform:videoAssertTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, selectedAsset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
}

#pragma mark - 动态水印
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoURL:(NSURL *)inputVideoURL andImageArray:(NSMutableArray *)imageArr andBeginTime:(float)beginTime isAudio:(BOOL)isAudio callback:(Callback )callBlock{
    
    // 1.
    if (!inputVideoURL || ![inputVideoURL isFileURL] || !exportVideoFile || [exportVideoFile isEqualToString:@""]) {
        NSLog(@"Input filename or Output filename is invalied for convert to Mp4!");
        return NO;
    }
    
    unlink([exportVideoFile UTF8String]);
    
    // 2. Create the composition and tracks
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
    NSParameterAssert(asset);
    if(asset ==nil || [[asset tracksWithMediaType:AVMediaTypeVideo] count]<1) {
        NSLog(@"Input video is invalid!");
        return NO;
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        // Retry once
        if (asset)
        {
            asset = nil;
        }
        
        asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
        assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([assetVideoTracks count] <= 0)
        {
            if (asset)
            {
                asset = nil;
            }
            
            NSLog(@"Error reading the transformed video track");
            return NO;
        }
    }
    
    // 3. Insert the tracks in the composition's tracks
    AVAssetTrack *assetVideoTrack = [assetVideoTracks firstObject];
    [videoTrack insertTimeRange:assetVideoTrack.timeRange ofTrack:assetVideoTrack atTime:CMTimeMake(0, 1) error:nil];
    [videoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    if (isAudio) {
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)
        {
            AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [audioTrack insertTimeRange:assetAudioTrack.timeRange ofTrack:assetAudioTrack atTime:CMTimeMake(0, 1) error:nil];
        }
        else
        {
            NSLog(@"Reminder: video hasn't audio!");
        }
    }
    
    // 4. Effects
    //效果
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    
    // Animation effects
    NSMutableArray *animatedLayers = [[NSMutableArray alloc] init];
    //可以留着
    CALayer *animatedLayer = [self buildAnimationImages:assetVideoTrack.naturalSize imagesArray:imageArr withTime:beginTime];
    
    if (animatedLayer) {
        [animatedLayers addObject:(id)animatedLayer];
    }
    
    if (animatedLayers && [animatedLayers count] > 0) {
        for (CALayer *animatedLayer in animatedLayers) {
            [parentLayer addSublayer:animatedLayer];
        }
    }
    
    // Make a "pass through video track" video composition.
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
    passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.frameDuration = CMTimeMake(1, 60); // 30 fps
    videoComposition.renderSize =  assetVideoTrack.naturalSize;
    
    parentLayer = nil;
    if (animatedLayers) {
        [animatedLayers removeAllObjects];
        animatedLayers = nil;
    }
    
    // 5. Music effect
    // 6. Export to mp4 （Attention: iOS 5.0不支持导出MP4，会crash）
    //    NSString *mp4Quality = AVAssetExportPresetMediumQuality; //AVAssetExportPresetPassthrough
    NSString *exportPath = exportVideoFile;
    NSURL *exportUrl = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1280x720];
    _exportSession.outputURL = exportUrl;
    _exportSession.outputFileType = AVFileTypeMPEG4;
    _exportSession.shouldOptimizeForNetworkUse = YES;
    
    if (videoComposition) {
        _exportSession.videoComposition = videoComposition;
    }
    
    // 7. Success status
    [_exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([_exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"MP4 Successful!");
                    callBlock(exportUrl,exportPath);
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    NSLog(@"导出失败");
                    callBlock(exportUrl,exportPath);
                    
                });
                
                NSLog(@"Export failed: %@", [[_exportSession error] localizedDescription]);
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog(@"Export Waiting");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                NSLog(@"Export Exporting");
                break;
            }
            default:
                break;
        }
        
        _exportSession = nil;
        
        if (asset){ }
    }];
    
    return YES;
}
//生成动画
- (CALayer*)buildAnimationImages:(CGSize)viewBounds imagesArray:(NSMutableArray *)imagesArray withTime:(float)beginTime {
    
    if ([imagesArray count] < 1)
    {
        return nil;
    }
    
    // Contains CMTime array for the time duration [0-1]
    NSMutableArray *keyTimesArray = [[NSMutableArray alloc] init];
    double currentTime = CMTimeGetSeconds(kCMTimeZero);
    DLYLog(@"成功生成片头片尾动画");
    
    for (int seed = 0; seed < [imagesArray count]; seed++)
    {
        NSNumber *tempTime = [NSNumber numberWithFloat:(currentTime + (float)seed/[imagesArray count])];
        [keyTimesArray addObject:tempTime];
    }
    
    //    UIImage *image = [UIImage imageWithCGImage:(CGImageRef)imagesArray[0]];
    //    AVSynchronizedLayer *animationLayer = [CALayer layer];
    CALayer *animationLayer = [CALayer layer];
    
    animationLayer.opacity = 1.0;
    animationLayer.frame = CGRectMake(0, 0, 900, 600);
    animationLayer.position = CGPointMake(640, 360);
    
    CAKeyframeAnimation *frameAnimation = [[CAKeyframeAnimation alloc] init];
    frameAnimation.beginTime = beginTime;
    [frameAnimation setKeyPath:@"contents"];
    frameAnimation.calculationMode = kCAAnimationDiscrete;
    //注释掉就OK了 是否留着最后一张或某一张
    //    [animationLayer setContents:[imagesArray lastObject]];
    
    frameAnimation.autoreverses = NO;
    frameAnimation.duration = 2.0;
    frameAnimation.repeatCount = 1;
    [frameAnimation setValues:imagesArray];
    [frameAnimation setKeyTimes:keyTimesArray];
    //    [frameAnimation setRemovedOnCompletion:NO];
    [animationLayer addAnimation:frameAnimation forKey:@"contents"];
    //        if (keyTimesArray)
    //        {
    //            [keyTimesArray release];
    //            keyTimesArray = nil;
    //        }
    //
    //        if (frameAnimation)
    //        {
    //            [frameAnimation release];
    //            frameAnimation = nil;
    //        }
    return animationLayer;
}
#pragma mark - 时间处理 -
- (float) switchTimeWithTemplateString:(NSString *)timeSting{
    
    float timePoint = 0;
    NSArray *startArr = [timeSting componentsSeparatedByString:@":"];
    
    for (int i = 0; i < 3; i ++) {
        NSString *timeStr = startArr[i];
        int time = [timeStr floatValue];
        if (i == 0) {
            timePoint = timePoint + time * 60 * 1000;
        }if (i == 1) {
            timePoint = timePoint + time * 1000;
        }else {
            timePoint = timePoint + time;
        }
    }
    return timePoint;
}
- (NSString *)returnFormatString:(NSString *)str {
    return [str stringByReplacingOccurrencesOfString:@" " withString:@" "];
}
//获取当地时间
- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy.MM.dd  HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}
- (long long)getDateTimeTOMilliSeconds:(NSDate *)datetime {
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval * 1000;
    return totalMilliseconds;
}

@end

