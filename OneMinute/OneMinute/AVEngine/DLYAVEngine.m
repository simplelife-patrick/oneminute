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


@interface DLYAVEngine ()<AVCaptureFileOutputRecordingDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,CAAnimationDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureVideoOrientation videoOrientation;
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
    
    int _channels;//音频通道
    Float64 _samplerate;//音频采样率
    AVAssetExportSession *_exportSession;
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideo;//记录上一次视频数据文件的CMTime
    CMTime _lastAudio;//记录上一次音频数据文件的CMTime
}

@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput           *metadataOutput;
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
@property (nonatomic, strong) NSMutableArray                    *transitionTimeRanges;
@property (nonatomic, strong) UIImagePickerController           *moviePicker;

@property (nonatomic, strong) DLYResource                       *resource;
@property (nonatomic, strong) DLYSession                        *session;

@property (nonatomic, strong) AVMutableVideoComposition         *videoComposition;
@property (nonatomic, strong) AVAssetExportSession              *assetExporter;

@property (atomic, assign) BOOL isCapturing;//正在录制
@property (atomic, assign) BOOL isPaused;//是否暂停
@property (atomic, assign) BOOL discont;//是否中断
@property (nonatomic, strong) NSMutableArray *imageArr;
@property (nonatomic, strong) NSTimer *recordTimer; //准备拍摄片段闪烁的计时器

//Reconstruction fast and slow
@property (nonatomic) CMTime                                   defaultMinFrameDuration;
@property (nonatomic) CMTime                                   defaultMaxFrameDuration;
@property (nonatomic, strong) NSString                         *currentMoviePath; // 当前到出的视频路径
@property (nonatomic, strong) NSString                         *plistPath;
@property (nonatomic, strong) DLYMiniVlogPart                  *currentPart;
@property (nonatomic, assign) DLYPhoneDeviceType               currentPhoneModel;

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

+ (instancetype) sharedDLYAVEngine{
    
    static DLYAVEngine *AVEngine;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AVEngine = [[DLYAVEngine alloc] init];
        
    });
    return AVEngine;
}
- (void)dealloc {
    
    [_captureSession stopRunning];
    _captureSession             = nil;
    _captureVideoPreviewLayer   = nil;
    
    _backCameraInput            = nil;
    _frontCameraInput           = nil;
    _audioMicInput              = nil;
    
    _audioOutput                = nil;
    _captureMovieFileOutput     = nil;
    
    _audioConnection            = nil;
    _videoConnection            = nil;
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

#pragma mark - 创建Recorder录制会话 -
-(AVCaptureSession *)captureSession{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
        
        //添加后置摄像头的输入
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self.captureSession addInput:self.backCameraInput];
        }else{
            DLYLog(@"Backcamera intput add faild !");
        }
        
        //添加麦克风的输入
        if ([_captureSession canAddInput:self.audioMicInput]) {
            [_captureSession addInput:self.audioMicInput];
        }else{
            DLYLog(@"Audio input add faild !");
        }
        
        //添加视频文件输出
        if ([_captureSession canAddOutput:self.captureMovieFileOutput]) {
            [_captureSession addOutput:self.captureMovieFileOutput];
            
        }
        //添加音频输出
        if ([_captureSession canAddOutput:self.audioOutput]) {
            [_captureSession addOutput:self.audioOutput];
        }else{
            DLYLog(@"Audio output add faild !");
        }
        //添加元数据输出
        if ([_captureSession canAddOutput:self.metadataOutput]) {
            [_captureSession addOutput:self.metadataOutput];
            self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
        }else{
            DLYLog(@"Metadate output add faild !");
        }
    }
    return _captureSession;
}

#pragma mark - Recorder录制会话 输入 配置 -
//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        
        AVCaptureDevice *device = _backCameraInput.device;
        if (device.isSmoothAutoFocusSupported) {
            
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
            }
        }
        
        if (error) {
            DLYLog(@"获取后置摄像头失败~");
        }else{
            
            DLYMobileDevice *mobileDevice = [DLYMobileDevice sharedDevice];
            DLYPhoneDeviceType phoneType = [mobileDevice iPhoneType];
            _currentPhoneModel = phoneType;
            
            NSString *phoneModel = [mobileDevice iPhoneModel];
            
            DLYLog(@"Current Phone Type: %@\n",phoneModel);
            
            if (phoneType == PhoneDeviceTypeIphone_7 || phoneType == PhoneDeviceTypeIphone_7_Plus || phoneType == PhoneDeviceTypeIphone_6s || phoneType == PhoneDeviceTypeIphone_6s_Plus || phoneType == PhoneDeviceTypeIphone_SE) {
                self.captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
            }else{
                self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
            }
        }
    }
    return _backCameraInput;
}
//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        AVCaptureDevice *device = _frontCameraInput.device;
        
        if (device.isSmoothAutoFocusSupported) {
            
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
            }
        }
        if (error) {
            DLYLog(@"获取前置摄像头失败~");
        }else{
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
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

#pragma mark - Recorder录制会话 输出 配置 -
//视频文件输出
-(AVCaptureMovieFileOutput *)captureMovieFileOutput{
    
    if (_captureMovieFileOutput == nil) {
        _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _captureMovieFileOutput;
}
//元数据输出
-(AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        dispatch_queue_t metadataOutputQueue = dispatch_queue_create("MetadataOutput", DISPATCH_QUEUE_SERIAL);
        [_metadataOutput setMetadataObjectsDelegate:self queue:metadataOutputQueue];
    }
    return _metadataOutput;
}
//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        //        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audiocapture", DISPATCH_QUEUE_SERIAL);
        [_audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    }
    return _audioOutput;
}

#pragma mark - Recorder录制会话 连接 配置 -
//视频连接
- (AVCaptureConnection *)videoConnection {
    if (!_videoConnection) {
        _videoConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

#pragma mark - 初始化AVEngine -
- (instancetype)initWithPreviewView:(UIView *)previewView{
    if (self = [super init]) {
        
        [self createTimer];
        
        //创建存储moviePaths的plist文件
        NSString *plistPath = [kPathDocument stringByAppendingPathComponent:@"moviePaths.plist"];
        
        _plistPath = plistPath;
        
        self.effectiveScale = 1.0;
        
        if (previewView) {
            self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
            self.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
            self.captureVideoPreviewLayer.frame = previewView.bounds;
            self.captureVideoPreviewLayer.contentsGravity = kCAGravityTopLeft;
            self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [previewView.layer addSublayer:self.captureVideoPreviewLayer];
        }
        
        // 判断当前视频设备是否支持光学防抖
        if ([_captureDeviceInput.device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
            // 如果支持防抖就打开防抖模式
            self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
        
        //设置视频录制的方向
        if ([self.videoConnection isVideoOrientationSupported]) {
            
            [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
        //视频录制队列
        movieWritingQueue = dispatch_queue_create("moviewriting", DISPATCH_QUEUE_SERIAL);
        
        // BufferQueue
        OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
        DLYLog(@"CMBufferQueueCreate error:%d", (int)err);
        
        self.metadataOutput.rectOfInterest = [self.captureVideoPreviewLayer metadataOutputRectOfInterestForRect:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        
        [self.captureSession startRunning];
    }
    return self;
}

#pragma mark - 切换摄像头 -
- (void)changeCameraInputDeviceisFront:(BOOL)isFront {
    
    NSLog(@"切换摄像头 <<<前>>> 的录制方向 :%ld",(long)self.videoConnection.videoOrientation);
    if (isFront) {
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.backCameraInput];
        
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.frontCameraInput];//切换成了前置
            self.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;

            self.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
        NSLog(@"✅✅✅当前视频连接的视频方向为 :%lu",self.videoConnection.videoOrientation);
        NSLog(@"✅✅✅当前预览方向为 :%lu",self.videoConnection.videoPreviewLayer.orientation);
    }else {
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.backCameraInput];//切换成了后置
            self.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;

            self.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
    }
    [self.captureSession commitConfiguration];
    NSLog(@"切换摄像头 <<<后>>> 的录制方向 :%ld",(long)self.videoConnection.videoOrientation);
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
            
            AVCaptureDevice *videoCaptureDevice = device;
            
            // 获取视频输入流
            NSError *error = nil;
            _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
            if (error) {
                // Handle the error appropriately.
                DLYLog(@"To Gain CaptureDevice Intput failed !");
            }
            
            _defaultFormat = device.activeFormat;
            DLYLog(@"当前选择的device.activeFormat :",_defaultFormat);
            _defaultMinFrameDuration = device.activeVideoMinFrameDuration;
            _defaultMaxFrameDuration = device.activeVideoMaxFrameDuration;
            
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
//顺时针旋转
- (void)changeCameraRotateClockwiseAnimation {
    CABasicAnimation *animation =  [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //默认是顺时针效果，若将fromValue和toValue的值互换，则为逆时针效果
    animation.fromValue = [NSNumber numberWithFloat:0.f];
    animation.toValue =  [NSNumber numberWithFloat: M_PI];
    animation.duration  = 0.2;
    animation.autoreverses = NO;
    animation.fillMode =kCAFillModeForwards;
    animation.repeatCount = 0;
    [self.captureVideoPreviewLayer addAnimation:animation forKey:nil];
}

//逆时针旋转
- (void)changeCameraRotateAnticlockwiseAnimation {
    CABasicAnimation *animation =  [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //默认是顺时针效果，若将fromValue和toValue的值互换，则为逆时针效果
    animation.fromValue = [NSNumber numberWithFloat: M_PI];
    animation.toValue = [NSNumber numberWithFloat:0.f];
    animation.duration  = 0.2;
    animation.autoreverses = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = 0;
    [self.captureVideoPreviewLayer addAnimation:animation forKey:nil];
}
- (void)animationDidStart:(CAAnimation *)anim {
    [self.captureSession startRunning];
}

#pragma mark - 点触设置曝光 -

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY);
};

- (void)focusOnceWithPoint:(CGPoint)point{
    
    AVCaptureDevice *captureDevice = _captureDeviceInput.device;
    
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
    
    AVCaptureDevice *captureDevice = _captureDeviceInput.device;
    CGPoint currentPoint = CGPointZero;
    
    if ([captureDevice lockForConfiguration:nil]) {
        
        //        CGFloat distance = distanceBetweenPoints(currentPoint, point);
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
        [captureDevice unlockForConfiguration];
        currentPoint = point;
        NSLog(@"Current point of the capture device is :x = %f,y = %f",currentPoint.x,currentPoint.y);
    }
}

-(void)focusAtPoint:(CGPoint)point{
    
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        
    }];
}

-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    
    AVCaptureDevice *captureDevice= [_captureDeviceInput device];
    NSError *error;
    
    if ([captureDevice lockForConfiguration:&error]) {
        
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

- (void)resetFormat {
    
    BOOL isRunning = self.captureSession.isRunning;
    
    if (isRunning) {
        [self.captureSession beginConfiguration];
    }
    
    [_captureDeviceInput.device lockForConfiguration:nil];
    
    _captureDeviceInput.device.activeFormat = self.defaultFormat;
    _captureDeviceInput.device.activeVideoMaxFrameDuration = _defaultMaxFrameDuration;
    _captureDeviceInput.device.activeVideoMinFrameDuration = _defaultMinFrameDuration;
    
    [_captureDeviceInput.device  unlockForConfiguration];
    
    if (isRunning) {
        [self.captureSession commitConfiguration];
    }
}

#pragma mark - 开始录制 -
- (void)startRecordingWithPart:(DLYMiniVlogPart *)part {
    _currentPart = part;
    if (!self.isCapturing) {
        self.isPaused = NO;
        self.isCapturing = YES;
    }
    
    if (part.recordType == DLYMiniVlogRecordTypeSlomo) {
        DLYLog(@"🎬🎬🎬Record Type Is Slomo");
        [self cameraBackgroundDidClickOpenSlow];
        
    }else if (part.recordType == DLYMiniVlogRecordTypeTimelapse){
        DLYLog(@"🎬🎬🎬Record Type Is Timelapse");
        [self cameraBackgroundDidClickCloseSlow];
    }else{
        DLYLog(@"🎬🎬🎬Record Type Is Normal");
        [self cameraBackgroundDidClickCloseSlow];
    }
    
    NSString *outputPath = [self.resource getSaveDraftPartWithPartNum:_currentPart.partNum];
    if (outputPath) {
        NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
        _currentPart.partUrl = outputUrl;
        DLYLog(@"第 %lu 个片段的地址 :%@",_currentPart.partNum + 1,_currentPart.partUrl);
    }else{
        DLYLog(@"片段地址获取为空");
    }
    [self.captureMovieFileOutput startRecordingToOutputFileURL:_currentPart.partUrl recordingDelegate:self];
}

#pragma mark - 停止录制 -
- (void)stopRecording {
    
    [self.captureMovieFileOutput stopRecording];
    
    if (self.isCapturing) {
        self.isPaused = YES;
    }
    _isRecording = NO;

}

#pragma mark - 取消录制 -
- (void)cancelRecording{
    [self.captureMovieFileOutput stopRecording];
    
    if (self.isCapturing) {
        self.isPaused = YES;
    }
    _isRecording = NO;
}

#pragma mark - 暂停录制 -
- (void) pauseRecording{
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}
#pragma mark - 视频速度处理 -

// 处理速度视频
- (void)setSpeedWithVideo:(NSURL *)videoPartUrl completed:(void(^)())completed {
    NSLog(@"处理视频速度🚀🚀🚀🚀🚀🚀🚀🚀🚀");
    // 获取视频
    if (!videoPartUrl) {
        DLYLog(@"待调速的视频片段地址为空");
        return;
    }else{
        
        AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoPartUrl options:nil];
        // 视频混合
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        // 视频轨道
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频轨道
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        // 插入视频轨道
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
        // 插入音频轨道
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
        
        // 适配视频速度比率
        CGFloat scale = 0;
        if(_currentPart.recordType == DLYMiniVlogRecordTypeTimelapse){
            scale = 0.4f;  // 0.2对应  快速 x5   播放时间压缩帧率平均(低帧率)
        } else if (_currentPart.recordType == DLYMiniVlogRecordTypeSlomo) {
            scale = 4.0f;  // 慢速 x4   播放时间拉长帧率平均(高帧率)
        }else{
            scale = 1.0f;
        }
        
        // 根据速度比率调节音频和视频
        [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) toDuration:CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale)];
        [compositionAudioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) toDuration:CMTimeMake(videoAsset.duration.value * scale, videoAsset.duration.timescale)];
        
        // 配置导出
        AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1920x1080];
        // 导出视频的临时保存路径
        
        NSString *exportPath;
        
        NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
            if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
                exportPath = [NSString stringWithFormat:@"%@/part%lu.mp4",draftPath,_currentPart.partNum];
            }
        }
        NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
        
        _assetExport.outputFileType = AVFileTypeMPEG4;
        _assetExport.outputURL = exportUrl;
        _assetExport.shouldOptimizeForNetworkUse = YES;
        
        // 导出视频
        [_assetExport exportAsynchronouslyWithCompletionHandler:^{
            completed();
        }];
    }
}
#pragma mark - 打开慢动作录制 -
- (void)cameraBackgroundDidClickOpenSlow {

    [self.captureSession stopRunning];
    CGFloat desiredFPS = 240.0;
    NSLog(@"当前设置的录制帧率是: %f",desiredFPS);
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [_captureDeviceInput.device formats]) {
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
    if (selectedFormat) {
        if ([_captureDeviceInput.device lockForConfiguration:nil]) {
            NSLog(@"selected format: %@", selectedFormat);
            _captureDeviceInput.device.activeFormat = selectedFormat;
            _captureDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            _captureDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [_captureDeviceInput.device unlockForConfiguration];
        }
    }
    [self.captureSession startRunning];
}
#pragma mark - 关闭慢动作录制 -
- (void)cameraBackgroundDidClickCloseSlow {
    
    [self.captureSession stopRunning];
    CGFloat desiredFPS = 60.0f;
    NSLog(@"当前设置的录制帧率是: %f",desiredFPS);
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [_captureDeviceInput.device formats]) {
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
    if (selectedFormat) {
        if ([_captureDeviceInput.device lockForConfiguration:nil]) {
            
//            _captureDeviceInput.device.activeFormat = _defaultFormat;
//            _captureDeviceInput.device.activeVideoMinFrameDuration = _defaultMinFrameDuration;
//            _captureDeviceInput.device.activeVideoMaxFrameDuration = _defaultMaxFrameDuration;
//            [_captureDeviceInput.device unlockForConfiguration];
            _captureDeviceInput.device.activeFormat = selectedFormat;
            _captureDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            _captureDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [_captureDeviceInput.device unlockForConfiguration];
        }
    }
    [self.captureSession startRunning];
}
#pragma mark - 内部处理方法
- (NSString *)movieName {
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"time_%ld", (long)[datenow timeIntervalSince1970]];
    return [timeSp stringByAppendingString:@".mov"];
}
#pragma mark - 重置录制session -
- (void) restartRecording{
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate -
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    DLYLog(@"开始录制,正在写入...");
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    DLYLog(@"结束录制,写入完成!!!");
    
    NSMutableDictionary *addData = [NSMutableDictionary dictionary];
    [addData setObject:_currentPart.partUrl forKey:[NSString stringWithFormat:@"part%luPath",_currentPart.partNum]];
    [addData setObject:@(_currentPart.recordType) forKey:@"recordType"];
    [addData setObject:@(_currentPart.partNum) forKey:@"partNum"];
    
    [addData writeToFile:_plistPath atomically:YES];
    
    typeof(self) weakSelf = self;
    [self setSpeedWithVideo:_currentPart.partUrl completed:^{
        DLYLog(@"第 %lu 个片段调速完成",weakSelf.currentPart.partNum + 1);
    }];
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
}
//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
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
                //                CGPoint point = CGPointMake(faceRegion.size.width/2, faceRegion.size.height/2);
                //                CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
                //                [self focusOnceWithPoint:cameraPoint];
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
#pragma mark - 获取视频某一帧图像 -

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

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
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
- (void) mergeVideoWithVideoTitle:(NSString *)videoTitle SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    NSMutableArray *videoArray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            
            for (NSInteger i = 0; i < [draftArray count]; i++) {
                NSString *path = draftArray[i];
                if ([path hasSuffix:@"mov"]) {
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",path];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    [videoArray addObject:url];
                }
            }
        }
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //可以改变视频方向,待测试使用
//    compositionVideoTrack.preferredTransform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
    
    Float64 tmpDuration =0.0f;
    
    for (int i=0; i < videoArray.count; i++)
    {
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:videoArray[i] options:nil];
        
        AVAssetTrack *videoAssetTrack = nil;
        AVAssetTrack *audioAssetTrack = nil;
        if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
            videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
            audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        }
        
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration);
        
        NSError *errorVideo = nil;
        [compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&errorVideo];
        if (errorVideo) {
            DLYLog(@"视频合成过程中视频轨道插入发生错误,错误信息 :%@",errorVideo);
        }
        
        NSError *errorAudio = nil;
        [compositionAudioTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&errorAudio];
        if (errorAudio) {
            DLYLog(@"视频合成过程音频轨道插入发生错误,错误信息 :%@",errorVideo);
        }
        
        tmpDuration += CMTimeGetSeconds(videoAssetTrack.timeRange.duration);
    }
    
    NSURL *outputUrl = [self.resource saveProductToSandbox];
    
    AVAssetExportSession *exporter = [self makeExportableWithAsset:mixComposition outputUrl:outputUrl videoComposition:nil andAudioMax:nil];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"⛳️⛳️⛳️全部片段merge成功");
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@".m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        
        [self addMusicToVideo:outputUrl audioUrl:BGMUrl videoTitle:videoTitle successBlock:successBlock failure:failureBlcok];
    }];
}

-(long long)getDateTimeTOMilliSeconds:(NSDate *)datetime {
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval * 1000;
    return totalMilliseconds;
}
#pragma mark - 片头 -
- (void) addVideoHeadertWithTitle:(NSString *)videoTitle SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    NSArray *videoPathArray = [self.resource loadDraftPartsFromeDocument];
    NSString *path = @"outputMovie1.mp4";
    
    unlink([path UTF8String]);
    
    NSString* mp4OutputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
    //    __weak typeof(self) weakSelf = self;
    
    self.imageArr = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //294
        for (int i = 6; i<294; i++)
        {
            @autoreleasepool {
                NSString *imageName = [NSString stringWithFormat:@"2_00%03d", i];
                UIImage *image = [UIImage imageNamed:imageName];
                UIImage *newImage = [weakSelf imageWithImageSimple:image scaledToSize:CGSizeMake(600, 600)];
                [weakSelf.imageArr addObject:(id)newImage.CGImage];
                //                DLYLog(@"%zd", weakSelf.imageArr.count);
            }
            
            if (self.imageArr.count == 288) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf buildVideoEffectsToMP4:mp4OutputFile inputVideoURL:videoPathArray[0] andImageArray:self.imageArr callback:^(NSURL *finalUrl, NSString *filePath) {
                        [weakSelf.imageArr removeAllObjects];
                        [weakSelf addTransitionEffectWithTitle:videoTitle andURL:finalUrl SuccessBlock:^{
                        } failure:^(NSError *error) {
                        }];
                        
                    }];
                });
                
            }
        }
    });
    
}

//压缩图片
- (UIImage *)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize {
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRelease(image.CGImage);
    image = nil;
    return newImage;
    
}
#pragma mark ==== 动态水印
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoURL:(NSURL *)inputVideoURL andImageArray:(NSMutableArray *)imageArr callback:(Callback )callBlock {
    
    // 1.
    if (!inputVideoURL || ![inputVideoURL isFileURL] || !exportVideoFile || [exportVideoFile isEqualToString:@""]) {
        NSLog(@"Input filename or Output filename is invalied for convert to Mp4!");
        return NO;
    }
    
    unlink([exportVideoFile UTF8String]);
    
    // 2. Create the composition and tracks
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
    NSParameterAssert(asset);
    if(asset == nil || [[asset tracksWithMediaType:AVMediaTypeVideo] count]<1) {
        NSLog(@"Input video is invalid!");
        return NO;
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
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
    
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)
    {
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:assetAudioTrack.timeRange ofTrack:assetAudioTrack atTime:CMTimeMake(0, 1) error:nil];
    }
    else
    {
        NSLog(@"Reminder: video hasn't audio!");
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
    //        UIImage *image = [UIImage imageWithCGImage:(CGImageRef)themeCurrent.animationImages[0]];
    CALayer *animatedLayer = [self buildAnimationImages:assetVideoTrack.naturalSize imagesArray:imageArr position:CGPointMake(10, 10)];
    
    
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
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    videoComposition.renderSize =  assetVideoTrack.naturalSize;
    
    parentLayer = nil;
    if (animatedLayers) {
        [animatedLayers removeAllObjects];
        animatedLayers = nil;
    }
    
    // 5. Music effect
    // 6. Export to mp4 （Attention: iOS 5.0不支持导出MP4，会crash）
    NSString *exportPath = exportVideoFile;
    NSURL *exportUrl = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    _exportSession.outputURL = exportUrl;
    _exportSession.outputFileType = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ? AVFileTypeMPEG4 : AVFileTypeQuickTimeMovie;
    
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
                    
                    DLYLog(@"MP4 Successful!");
                    callBlock(exportUrl,exportPath);
                    
//                    NSLog(@"Output Mp4 is %@", exportVideoFile);
                    
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
//                    NSLog(@"导出失败");
                    
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
        
    }];
    
    if (asset){
        
        asset = nil;
    }
    
    return YES;
}

//生成动画
- (CALayer*)buildAnimationImages:(CGSize)viewBounds imagesArray:(NSMutableArray *)imagesArray position:(CGPoint)position {
    
    if ([imagesArray count] < 1)
    {
        return nil;
    }
    
    // Contains CMTime array for the time duration [0-1]
    NSMutableArray *keyTimesArray = [[NSMutableArray alloc] init];
    double currentTime = CMTimeGetSeconds(kCMTimeZero);
    NSLog(@"currentDuration %f",currentTime);
    
    for (int seed = 0; seed < [imagesArray count]; seed++)
    {
        NSNumber *tempTime = [NSNumber numberWithFloat:(currentTime + (float)seed/[imagesArray count])];
        [keyTimesArray addObject:tempTime];
    }
    
    //    UIImage *image = [UIImage imageWithCGImage:(CGImageRef)imagesArray[0]];
    //    AVSynchronizedLayer *animationLayer = [CALayer layer];
    CALayer *animationLayer = [CALayer layer];
    
    animationLayer.opacity = 1.0;
    animationLayer.frame = CGRectMake(0, 0, 1000, 900);
    animationLayer.position = CGPointMake(360, 200);
    
    CAKeyframeAnimation *frameAnimation = [[CAKeyframeAnimation alloc] init];
    frameAnimation.beginTime = 0.1;
    [frameAnimation setKeyPath:@"contents"];
    frameAnimation.calculationMode = kCAAnimationDiscrete;
    //注释掉就OK了 是否留着最后一张或某一张
    //    [animationLayer setContents:[imagesArray lastObject]];
    
    frameAnimation.autoreverses = NO;
    frameAnimation.duration = 5.0;
    frameAnimation.repeatCount = 1;
    [frameAnimation setValues:imagesArray];
    [frameAnimation setKeyTimes:keyTimesArray];
    //    [frameAnimation setRemovedOnCompletion:NO];
    [animationLayer addAnimation:frameAnimation forKey:@"contents"];
    return animationLayer;
    
}

-(NSString *)returnFormatString:(NSString *)str {
    return [str stringByReplacingOccurrencesOfString:@" " withString:@" "];
}

#pragma mark - 转场 -
- (void) addTransitionEffectWithTitle:(NSString *)videoTitle andURL:(NSURL*)newUrl SuccessBlock:(SuccessBlock)successBlock failure:(FailureBlock)failureBlcok{
    
    self.composition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *compositionTrackA = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *compositionTrackB = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *compositionTrackAudio = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    NSArray *videoTracks = @[compositionTrackA, compositionTrackB];
    
    CMTime videoCursorTime = kCMTimeZero;
    CMTime transitionDuration = CMTimeMake(1, 1);
    CMTime audioCursorTime = kCMTimeZero;
    
    NSArray *videoPathArray = [self.resource loadDraftPartsFromeDocument];
    
    for (NSUInteger i = 0; i < videoPathArray.count; i++) {
        
        NSUInteger trackIndex = i % 2;
        
        AVURLAsset *asset;
        if (i == 0) {
            asset = [AVURLAsset URLAssetWithURL:newUrl options:nil];
            NSLog(@"self.videoPathArray[%lu]: %@",(unsigned long)i,videoPathArray[i]);
            //获取时长
            Duration duration =(UInt32)asset.duration.value / asset.duration.timescale;
            NSLog(@"AVFoundation获取时长 :%d",duration);
            
            DLYMovieObject *movieObj = [[DLYMovieObject alloc] initWithVideo:newUrl.absoluteString];
            NSLog(@"ffmpeg获取的时长: %f",movieObj.duration);
        }else {
            asset = [AVURLAsset URLAssetWithURL:videoPathArray[i] options:nil];
            NSLog(@"self.videoPathArray[%lu]: %@",(unsigned long)i,videoPathArray[i]);
            //获取时长
            Duration duration =(UInt32)asset.duration.value / asset.duration.timescale;
            NSLog(@"AVFoundation获取时长 :%d",duration);
            
            NSURL *videoUrl = videoPathArray[i];
            DLYMovieObject *movieObj = [[DLYMovieObject alloc] initWithVideo:videoUrl.absoluteString];
            NSLog(@"ffmpeg获取的时长: %f",movieObj.duration);
        }

        
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
        
        BOOL isInsertVideoSuccess = [currentTrack insertTimeRange:timeRange
                              ofTrack:assetVideoTrack
                               atTime:videoCursorTime error:nil];
        BOOL isInsertAudioSuccess = [compositionTrackAudio insertTimeRange:timeRange
                                       ofTrack:assetAudioTrack
                                        atTime:audioCursorTime error:nil];
        
        videoCursorTime = CMTimeAdd(videoCursorTime, timeRange.duration);
        videoCursorTime = CMTimeSubtract(videoCursorTime, transitionDuration);
        audioCursorTime = CMTimeAdd(audioCursorTime, timeRange.duration);
        
        if (i + 1 < videoPathArray.count) {
            timeRange = CMTimeRangeMake(videoCursorTime, transitionDuration);
            NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            [self.transitionTimeRanges addObject:timeRangeValue];
        }
    }
    
    AVVideoComposition *videoComposition = [self buildVideoComposition];
    
    NSURL *outputUrl = [self.resource saveProductToSandbox];
    self.currentProductUrl = outputUrl;
    
    AVAssetExportSession *exporter = [self makeExportableWithAsset:self.composition outputUrl:outputUrl videoComposition:videoComposition andAudioMax:nil];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        DLYLog(@"合并及转场操作成功");
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@".m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        
        [self addMusicToVideo:outputUrl audioUrl:BGMUrl videoTitle:videoTitle successBlock:successBlock failure:failureBlcok];
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
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    NSError *error = nil;
    if (videoAssetTrack) {
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    }
    if (audioAssetTrack) {
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    }
    
    //调整视频方向
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
        CALayer *watermarkLayer = [self addTitleForVideoWith:videoTitle size:renderSize];
        
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
        
        //时长小于1s的片段音轨平滑特殊处理
        float rampOffsetValue = 1;
        
        _prePoint = CMTimeMake(stopTime - rampOffsetValue, 1);
        CMTime duration = CMTimeSubtract(_stopTime, _prePoint);
        
        CMTimeRange timeRange = CMTimeRangeMake(_startTime, duration);
        CMTimeRange preTimeRange = CMTimeRangeMake(_prePoint, CMTimeMake(2, 1));
        
        if (part.soundType == DLYMiniVlogAudioTypeMusic) {//空镜
            [BGMParameters setVolumeRampFromStartVolume:1.0 toEndVolume:1.0 timeRange:timeRange];
            //            [BGMParameters setVolumeRampFromStartVolume:5.0 toEndVolume:0.4 timeRange:preTimeRange];
            
            [videoParameters setVolumeRampFromStartVolume:0 toEndVolume:0 timeRange:timeRange];
        }else if(part.soundType == DLYMiniVlogAudioTypeNarrate){//人声
            [videoParameters setVolumeRampFromStartVolume:2.0 toEndVolume:2.0 timeRange:timeRange];
            [BGMParameters setVolumeRampFromStartVolume:0.1 toEndVolume:0.1 timeRange:timeRange];
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
    
    AVAssetExportSession *assetExportSession = [self makeExportableWithAsset:mixComposition outputUrl:outPutUrl videoComposition:mutableVideoComposition andAudioMax:audioMix];
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([assetExportSession status]) {
            case AVAssetExportSessionStatusFailed:{
                DLYLog(@"配音失败: %@",[[assetExportSession error] description]);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                successBlock();
                if ([self.delegate  respondsToSelector:@selector(didFinishEdititProductUrl:)]) {
                    [self.delegate didFinishEdititProductUrl:outPutUrl];
                }
                ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
                [assetLibrary saveVideo:outPutUrl toAlbum:@"OneMinute" completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    DLYLog(@"⛳️⛳️⛳️配音完成后保存在手机相册");
                } failureBlock:^(NSError *error) {
                    
                }];
            }break;
            default:
                break;
        }
    }];
}
#pragma mark - 水印标题设置 -
- (CALayer *) addTitleForVideoWith:(NSString *)titleText size:(CGSize)renderSize{
    
    CALayer *overlayLayer = [CALayer layer];
    CATextLayer *titleLayer = [CATextLayer layer];
    UIFont *font = [UIFont systemFontOfSize:80.0];
    
    [titleLayer setFontSize:80.f];
    [titleLayer setFont:@"ArialRoundedMTBold"];
    [titleLayer setString:titleText];
    [titleLayer setAlignmentMode:kCAAlignmentCenter];
    [titleLayer setForegroundColor:[[UIColor yellowColor] CGColor]];
    titleLayer.contentsCenter = overlayLayer.contentsCenter;
    CGSize textSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    titleLayer.bounds = CGRectMake(0, 0, textSize.width + 50, textSize.height + 25);
    
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    NSDictionary *subTitleDic = template.subTitle1;
    NSString *subTitleStart = [subTitleDic objectForKey:@"startTime"];
    NSString *subTitleStop = [subTitleDic objectForKey:@"stopTime"];
    
    float _subTitleStart = [self switchTimeWithTemplateString:subTitleStart]/1000;
    float _subTitleStop = [self switchTimeWithTemplateString:subTitleStop]/1000;
    float duration = _subTitleStop - _subTitleStart;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:0.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.repeatCount = 0;
    animation.duration = _subTitleStart;
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    [titleLayer addAnimation:animation forKey:@"opacityAniamtion"];
    
    CABasicAnimation *animation1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation1.fromValue = [NSNumber numberWithFloat:1.0f];
    animation1.toValue = [NSNumber numberWithFloat:0.0f];
    animation1.repeatCount = 0;
    animation1.duration = duration;
    [animation1 setRemovedOnCompletion:NO];
    [animation1 setFillMode:kCAFillModeForwards];
    animation1.beginTime = _subTitleStart;
    [titleLayer addAnimation:animation1 forKey:@"opacityAniamtion1"];
    
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
#pragma mark - 导出工具 -
- (AVAssetExportSession *)makeExportableWithAsset:(AVMutableComposition *)composition outputUrl:(NSURL *)outputUrl videoComposition:(AVVideoComposition *)videoComposition andAudioMax:(AVAudioMix *)audioMax{
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    assetExportSession.outputURL = outputUrl;
    assetExportSession.audioMix = audioMax;
    assetExportSession.videoComposition = videoComposition;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    return assetExportSession;
}
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
@end
