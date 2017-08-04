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
#import <math.h>

@interface DLYAVEngine ()
{
    CMTime defaultVideoMaxFrameDuration;
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureVideoOrientation referenceOrientation;
    dispatch_queue_t movieWritingQueue;
    CMBufferQueueRef previewBufferQueue;
    BOOL recordingWillBeStarted;
    
    CMTime _startTime;
    CMTime _stopTime;
    CGSize videoSize;
    NSURL *fileUrl;
    
    BOOL isMicGranted;//麦克风权限是否被允许
}

@property (nonatomic, strong) AVCaptureVideoDataOutput          *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput          *movieFileOutput;
@property (nonatomic, strong) AVCaptureDeviceInput              *backCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *audioMicInput;
@property (nonatomic, strong) AVCaptureDeviceFormat             *defaultFormat;
@property (nonatomic, strong) AVCaptureConnection               *audioConnection;

// For video data output
@property (nonatomic, strong) AVAssetWriter                     *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterAudioInput;

@property (nonatomic, strong) GPUImageMovie                     *alphaMovie;
@property (nonatomic, strong) GPUImageMovie                     *bodyMovie;
@property (nonatomic, strong) GPUImageMovieWriter               *movieWriter;
@property (nonatomic, strong) GPUImageChromaKeyBlendFilter      *filter;
typedef void ((^MixcompletionBlock) (NSURL *outputUrl));

@property (nonatomic, strong) AVMutableComposition              *composition;
@property (nonatomic, strong) NSMutableArray                    *passThroughTimeRanges;
@property (nonatomic, copy) NSMutableArray                    *transitionTimeRangeArray;
@property (nonatomic, strong) UIImagePickerController           *moviePicker;

@property (nonatomic, strong) DLYResource                       *resource;
@property (nonatomic, strong) DLYSession                        *session;

@property (nonatomic, strong) AVMutableVideoComposition         *videoComposition;




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
#pragma mark - lazy load -

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

-(AVMutableComposition *)composition{
    if (!_composition) {
        _composition = [AVMutableComposition composition];
    }
    return _composition;
}

-(NSMutableArray *)transitionTimeRangeArray{
    if (!_transitionTimeRangeArray) {
        _transitionTimeRangeArray = [NSMutableArray array];
    }
    return _transitionTimeRangeArray;
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
//摄像头切换旋转动画
- (void)changeCameraRotateAnimation {
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.2;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionPush;
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
}
//摄像头切换翻转动画
- (void)changeCameraAnimation {
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.3;
    changeAnimation.type = @"Cube";
    changeAnimation.subtype = kCATransitionFromRight;
    //    changeAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [self.previewLayer addAnimation:changeAnimation forKey:@"changeAnimation"];
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
    
    [[self.previewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
    
    readyToRecordVideo = NO;
}
#pragma mark - 点触设置曝光 -

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    NSLog(@"deltaX = %f",deltaX);
    CGFloat deltaY = second.y - first.y;
    NSLog(@"deltaY = %f",deltaY);
    return sqrt(deltaX*deltaX + deltaY*deltaY);
};

-(void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = _currentVideoDeviceInput.device;
    CGPoint currentPoint = CGPointZero;
    
    if ([_currentVideoDeviceInput.device lockForConfiguration:nil]) {
        
        CGFloat distance = distanceBetweenPoints(currentPoint, point);
        NSLog(@"distance = %f",distance);
        // 设置对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && distance > 0.1 && distance != 0) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        
        // 设置曝光
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure] && distance > 0.1 && distance != 0) {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
        
        //设置白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance] && distance > 0.1 && distance != 0) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_currentVideoDeviceInput.device unlockForConfiguration];
        currentPoint = point;
        NSLog(@"current point of the capture device is :x = %f,y = %f",currentPoint.x,currentPoint.y);
    }
    
}

-(void)focusAtPoint:(CGPoint)point{
    
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        
        // 设置对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
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
    }];
}

-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    
    AVCaptureDevice *captureDevice= [self.currentVideoDeviceInput device];
    NSError *error;
    
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
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
                                               [NSNumber numberWithInteger:bitsPerSecond],AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
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
            
            DLYLog(@"AVAssetWriter startWriting error:%@", self.assetWriter.error);
        }
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        
        if (mediaType == AVMediaTypeVideo) {
            
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                
                if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                    
                    DLYLog(@"isRecording:%d, willBeStarted:%d", self.isRecording, recordingWillBeStarted);
                    DLYLog(@"AVAssetWriterInput video appendSampleBuffer error:%@", self.assetWriter.error);
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
                DLYLog(@"最终设定的最佳帧率: %f",desiredFPS);
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
- (void)startRecordingWithPart:(DLYMiniVlogPart *)part {
    
    self.currentPart = part;
//    CGFloat desiredFps = 0.0;
//    
//    if (part.recordType == DLYMiniVlogRecordTypeSlomo) {
//        
//        DLYLog(@"The record type is Slomo");
//        desiredFps = 240.0;
//    }else if(part.recordType == DLYMiniVlogRecordTypeTimelapse){
//        
//        DLYLog(@"The record type is TimeLapse");
//        desiredFps = 60.0;
//        _isTime = YES;
//    }else{
//        desiredFps = 60.0;
//        DLYLog(@"The record type is Normal");
//    }
//    [self switchFormatWithDesiredFPS:desiredFps];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (desiredFps > 0.0) {
//            [self switchFormatWithDesiredFPS:desiredFps];
//        }
//        else {
//            [self resetFormat];
//        }
//        
//    });
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(queue, ^{
//    
//        if (desiredFps > 0.0) {
//            [self switchFormatWithDesiredFPS:desiredFps];
//        }
//        else {
//            [self resetFormat];
//        }
//    
//    });
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    // Don't update the reference orientation when the device orientation is face up/down or unknown.
    if (UIDeviceOrientationIsLandscape(orientation)) {
        referenceOrientation = (AVCaptureVideoOrientation)orientation;
    }
    
    DLYResource *resource = [[DLYResource alloc] init];
    fileUrl = [resource saveDraftPartWithPartNum:part.partNum];
    
    NSError *error;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
    DLYLog(@"AVAssetWriter error:%@", error);
    
    recordingWillBeStarted = YES;
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
                    [self.delegate didFinishRecordingToOutputFileAtURL:fileUrl error:nil];
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
- (void) mergeVideoWithSuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    NSArray *videoArray = [self.resource loadBDraftParts];
    
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
        if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration);
        
//        NSUInteger second = 0;
//        second = videoAsset.duration.value / videoAsset.duration.timescale; // 获取视频总时长,单位秒
//        Float64 dur = CMTimeGetSeconds(videoAsset.duration);
        
        [compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        [compositionAudioTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        tmpDuration += CMTimeGetSeconds(videoAssetTrack.timeRange.duration);
    }
    
    DLYResource *resource = [[DLYResource alloc]init];
    NSURL *outputUrl = [resource saveProductToSandbox];
//    self.currentProductUrl = outputUrl;

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1920x1080];
    exporter.outputURL = outputUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"草稿片段mgerge成功");
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:@"UniversalTemplateBGM.m4a" ofType:nil];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        
        [self addMusicToVideo:outputUrl audioUrl:BGMUrl successBlock:successBlock failure:failureBlcok];
    }];
}

-(long long)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval*1000;
    return totalMilliseconds;
}
#pragma mark - 转场 -

- (void) addTransitionEffectSuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    [self buildCompositionTracks];
    
    AVVideoComposition *videoComposition = [self buildVideoComposition];
    [self transitionInstructionsInVideoComposition:videoComposition];
    
    NSURL *outPutUrl = [self.resource saveProductToSandbox];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = outPutUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        UISaveVideoAtPathToSavedPhotosAlbum([outPutUrl path], self, nil, nil);
        NSLog(@"过渡动画合成完毕");
        if (successBlock) {
            
            NSString *BGMPath = [[NSBundle mainBundle] pathForResource:@"BGM003.m4a" ofType:nil];
            NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
            self.currentProductUrl = outPutUrl;
            
            [self addMusicToVideo:self.currentProductUrl audioUrl:BGMUrl successBlock:successBlock failure:failureBlcok];
        }
    }];
    
}
- (void)buildCompositionTracks {
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    
    AVMutableCompositionTrack *compositionTrackA = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    
    AVMutableCompositionTrack *compositionTrackB = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    
    AVMutableCompositionTrack *compositionTrackAudio = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    NSArray *videoTracks = @[compositionTrackA, compositionTrackB];
    
    CMTime videoCursorTimeBefor = kCMTimeZero;
    CMTime videoCursorTimeAfter = kCMTimeZero;
    
    CMTime transitionDuration = CMTimeMake(2, 1);
    CMTime audioCursorTime = kCMTimeZero;
    
    NSArray *videoArray = [self.resource loadBDraftParts];
    
    for (NSUInteger i = 0; i < videoArray.count; i++) {
        
        NSUInteger trackIndex = i % 2;
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
        DLYLog(@"self.videoPathArray[%lu]: %@",(unsigned long)i,videoArray[i]);
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        
        if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        DLYLog(@"当前compositiontrack :%lu",trackIndex);
        AVMutableCompositionTrack *currentTrack = videoTracks[trackIndex];
        
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, assetVideoTrack.timeRange.duration);
        
        // Overlap clips by transition duration
        videoCursorTimeBefor = CMTimeAdd(videoCursorTimeBefor, timeRange.duration);
        DLYLog(@"正常cursor时间");
        CMTimeShow(videoCursorTimeBefor);
        
        videoCursorTimeAfter = CMTimeSubtract(videoCursorTimeBefor, transitionDuration);
        DLYLog(@"重叠插入cursor时间");
        CMTimeShow(videoCursorTimeAfter);
        
        audioCursorTime = CMTimeAdd(videoCursorTimeAfter, timeRange.duration);
        DLYLog(@"音频插入cursor时间");
        CMTimeShow(audioCursorTime);
        
        [currentTrack insertTimeRange:timeRange
                              ofTrack:assetVideoTrack
                               atTime:videoCursorTimeAfter error:nil];
        [compositionTrackAudio insertTimeRange:timeRange
                                       ofTrack:assetAudioTrack
                                        atTime:audioCursorTime error:nil];
        
        
        if (i + 1 < videoArray.count) {
            timeRange = CMTimeRangeMake(videoCursorTimeAfter, transitionDuration);
            NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            [self.transitionTimeRangeArray addObject:timeRangeValue];
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
        
        DLYVideoTransitionType type = instructions.transition.type;
        
        if (type == DLYVideoTransitionTypeDissolve) {
            
            [fromLayer setOpacityRampFromStartOpacity:1.0
                                         toEndOpacity:0.0
                                            timeRange:timeRange];
            
        }else if (type == DLYVideoTransitionTypePush) {
            
            // Define starting and ending transforms
            CGAffineTransform identityTransform = CGAffineTransformIdentity;
            
            CGFloat videoWidth = videoComposition.renderSize.width;
            
            CGAffineTransform fromDestTransform =
            CGAffineTransformMakeTranslation(-videoWidth, 0.0);
            
            CGAffineTransform toStartTransform =
            CGAffineTransformMakeTranslation(videoWidth, 0.0);
            
            [fromLayer setTransformRampFromStartTransform:identityTransform
                                           toEndTransform:fromDestTransform
                                                timeRange:timeRange];
            
            [toLayer setTransformRampFromStartTransform:toStartTransform
                                         toEndTransform:identityTransform
                                              timeRange:timeRange];
            
        }else if (type == DLYVideoTransitionTypeWipe) {
            
            CGFloat videoWidth = videoComposition.renderSize.width;
            CGFloat videoHeight = videoComposition.renderSize.height;
            
            CGRect startRect = CGRectMake(0.0f, 0.0f, videoWidth, videoHeight);
            CGRect endRect = CGRectMake(0.0f, videoHeight, videoWidth, 0.0f);
            
            [fromLayer setCropRectangleRampFromStartCropRectangle:startRect
                                               toEndCropRectangle:endRect
                                                        timeRange:timeRange];
        }else if (type == DLYVideoTransitionTypeClockwiseRotate){

            [fromLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(0, 0, 300, 300)
                                               toEndCropRectangle:CGRectMake(50, 50, 500, 300)
                                                        timeRange:timeRange];
            [toLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(100, 100, 200, 300)
                                               toEndCropRectangle:CGRectMake(0, 0, 500, 500)
                                                        timeRange:timeRange];
        }else if (type == DLYVideoTransitionTypeZoom){
            
            
            // Define starting and ending transforms
            CGAffineTransform identityTransform = CGAffineTransformIdentity;
            
            CGFloat videoWidth = videoComposition.renderSize.width;
            
            CGAffineTransform fromDestTransform = CGAffineTransformMakeTranslation(-videoWidth, 0.0);

            CGAffineTransform toStartTransform = CGAffineTransformMakeTranslation(videoWidth, 0.0);

            [fromLayer setTransformRampFromStartTransform:identityTransform
                                           toEndTransform:fromDestTransform
                                                timeRange:timeRange];

            [toLayer setTransformRampFromStartTransform:toStartTransform
                                         toEndTransform:identityTransform
                                              timeRange:timeRange];
        }
        
        instructions.compositionInstruction.layerInstructions = @[fromLayer,toLayer];
    }
    return videoComposition;
}
- (NSArray *)transitionInstructionsInVideoComposition:(AVVideoComposition *)videoComposition {
    
    NSMutableArray *transitionInstructions = [NSMutableArray array];
    
    int layerInstructionIndex = 1;
    
    //拿到videoComposition的指令集
    NSArray *compositionInstructions = videoComposition.instructions;
    
    // 遍历指令集
    for (AVMutableVideoCompositionInstruction *videoCompositionInstruction in compositionInstructions) {
        
        if (videoCompositionInstruction.layerInstructions.count == 2) {
            
            DLYTransitionInstructions *instructions = [[DLYTransitionInstructions alloc] init];
            
            instructions.compositionInstruction = videoCompositionInstruction;
            
            instructions.fromLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)videoCompositionInstruction.layerInstructions[1 - layerInstructionIndex];
            
            instructions.toLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)videoCompositionInstruction.layerInstructions[layerInstructionIndex];
            
            [transitionInstructions addObject:instructions];
            
            layerInstructionIndex = layerInstructionIndex == 1 ? 0 : 1;
        }
    }
    
    for (NSUInteger i = 0; i < transitionInstructions.count; i++) {
        
        
        DLYMiniVlogTemplate *currentTemplate = self.session.currentTemplate;
        NSArray *array = currentTemplate.parts;
        
        for (int i = 0; i < array.count; i++) {
            DLYMiniVlogPart *part = [[DLYMiniVlogPart alloc] init];
            part = array[i];
            DLYTransitionInstructions *tis = transitionInstructions[i];
            DLYVideoTransition *videoTransition = [DLYVideoTransition videoTransition];
            videoTransition.type = part.transitionType;
            tis.transition = videoTransition;
            transitionInstructions[i] = tis;
        }
    }
    return transitionInstructions;
}
#pragma mark - 配音 -
- (void) addMusicToVideo:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl successBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    //加载素材
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
    
    //创建视频编辑工程
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //将视音频素材加入编辑工程
    AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error = nil;
    
    if (videoAssetTrack) {
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    }
    if (audioAssetTrack) {
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    }
    
    //调整视频方向
    [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
    
#pragma mark - 添加标题 -
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    if ([[mixComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        // build a pass through video composition
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
        mutableVideoComposition.renderSize = videoAssetTrack.naturalSize;
        
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
        
        AVAssetTrack *videoTrack = [mixComposition tracksWithMediaType:AVMediaTypeVideo][0];
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        passThroughInstruction.layerInstructions = @[passThroughLayer];
        mutableVideoComposition.instructions = @[passThroughInstruction];
        
        
        
        videoSize = mutableVideoComposition.renderSize;
        CALayer *watermarkLayer = [self addTitleForVideoWith:@"DLY Mini VLOG" size:videoSize];
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
        videoLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        watermarkLayer.position = CGPointMake(mutableVideoComposition.renderSize.width/2, mutableVideoComposition.renderSize.height/2);
        [parentLayer addSublayer:watermarkLayer];
        mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }

    //处理视频原声
    AVAssetTrack *originalAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVMutableCompositionTrack *originalAudioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *videoParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:originalAudioCompositionTrack];
    AVMutableAudioMixInputParameters *BGMParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
    
    NSArray *partArray = self.session.currentTemplate.parts;
    
    for (NSInteger i = 0; i < partArray.count; i++) {
        
        DLYMiniVlogPart *part = partArray[i];
        
        NSArray *startArr = [part.starTime componentsSeparatedByString:@":"];
        NSString *startTimeStr = startArr[1];
        float startTime = [startTimeStr floatValue];
        _startTime = CMTimeMake(startTime, 1);
        
        NSArray *stopArr = [part.stopTime componentsSeparatedByString:@":"];
        NSString *stopTimeStr = stopArr[1];
        float stopTime = [stopTimeStr floatValue];
        _stopTime = CMTimeMake(stopTime, 1);
        
        CMTime duration = CMTimeSubtract(_stopTime, _startTime);
        CMTimeRange timeRange = CMTimeRangeMake(_startTime, duration);
        DLYLog(@"第 %lu 个part的timeRange",i);
        CMTimeShow(_startTime);
        CMTimeShow(duration);
        
        if (part.soundType == DLYMiniVlogAudioTypeMusic) {//空镜
            [BGMParameters setVolumeRampFromStartVolume:5.0 toEndVolume:5.0 timeRange:timeRange];
            [videoParameters setVolumeRampFromStartVolume:0 toEndVolume:0 timeRange:timeRange];
        }else if(part.soundType == DLYMiniVlogAudioTypeNarrate){//人声
            [videoParameters setVolumeRampFromStartVolume:5.0 toEndVolume:5.0 timeRange:timeRange];
            [BGMParameters setVolumeRampFromStartVolume:0.4 toEndVolume:0.4 timeRange:timeRange];
        }
    }
    audioMix.inputParameters = @[videoParameters,BGMParameters];
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    
    NSURL *outPutUrl = [self.resource saveProductToSandbox];
    self.currentProductUrl = outPutUrl;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.currentProductUrl.absoluteString])
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.currentProductUrl.absoluteString error:nil];
    }
    
    //输出设置
    assetExportSession.outputURL = outPutUrl;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.videoComposition = mutableVideoComposition;
    assetExportSession.audioMix = audioMix;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExportSession status]) {
            case AVAssetExportSessionStatusFailed:{
                DLYLog(@"配音失败: %@",[[assetExportSession error] description]);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                UISaveVideoAtPathToSavedPhotosAlbum([outPutUrl path], nil, nil, nil);
                DLYLog(@"配音完成后保存在手机相册");
            }break;
            default:
                break;
        }
        if (successBlock) {
            DLYLog(@"合并配音流程结束!");
            successBlock();
        }
    }];
}
#pragma mark - 标题 -

- (CALayer *) addTitleForVideoWith:(NSString *)titleText size:(CGSize)videoSize{
    
    CALayer *overlayLayer = [CALayer layer];
    CATextLayer *titleLayer = [CATextLayer layer];
    [titleLayer setFontSize:30];
    UIFont *font = [UIFont fontWithName:@"ArialRoundedMTBold" size:80.0f];
    [titleLayer setString:titleText];
    [titleLayer setAlignmentMode:kCAAlignmentCenter];
    [titleLayer setForegroundColor:[[UIColor yellowColor] CGColor]];
    CGSize textSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    titleLayer.contentsCenter = overlayLayer.contentsCenter;
    titleLayer.bounds = CGRectMake(0, 0, textSize.width + 50, textSize.height + 25);
    
    titleLayer.masksToBounds = YES;
    titleLayer.cornerRadius = 50.0f;
    [titleLayer setBackgroundColor:[UIColor colorWithHex:@"#87CEFA"].CGColor];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.repeatCount = 0;
    animation.duration = 8.0f;
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    [titleLayer addAnimation:animation forKey:@"opacityAniamtion"];
    
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    anima.toValue =(id) [UIColor greenColor].CGColor;
    anima.duration = 5.0f;
    
    [titleLayer addAnimation:anima forKey:@"backgroundAnimation"];
    
    
    [overlayLayer addSublayer:titleLayer];
    
    return overlayLayer;
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
    NSURL *outputUrl = [resource saveToSandboxFolderType:NSDocumentDirectory subfolderName:@"HeaderVideos" suffixType:@".mp4"];
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

- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    
}

@end
