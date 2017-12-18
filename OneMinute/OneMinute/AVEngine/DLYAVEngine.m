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
#import "DLYTransitionInstructions.h"
#import "DLYVideoTransition.h"
#import "DLYResource.h"
#import "DLYSession.h"
#import <math.h>
#import <CoreMotion/CoreMotion.h>
#import "UIImage+Extension.h"
#import "DLYPhotoAlbum.h"
#import "DLYMiniVlogVirtualPart.h"
#import "DLYPreviewView.h"
#import "DLYCaptureConfigErrorDelegate.h"

#import <UIKit/UIKit.h>

@interface DLYAVEngine ()<AVCaptureFileOutputRecordingDelegate,AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,CAAnimationDelegate,AVCaptureMetadataOutputObjectsDelegate,DLYRecordTimerDelegate,DLYMovieWriterDelegate,DLYCaptureConfigErrorDelegate>
{
    CMTime defaultVideoMaxFrameDuration;
    CMTime defaultVideoMinFrameDuration;
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;
    
    AVCaptureVideoOrientation videoOrientation;
    CMBufferQueueRef previewBufferQueue;
    
    CMTime _startTime;
    CMTime _stopTime;
    CMTime _prePoint;
    
    CGSize videoSize;
    NSURL *fileUrl;
    CGRect faceRegion;
    CGRect lastFaceRegion;
    BOOL _isSupportFaceReconginition;
    BOOL isMicGranted;
    
    NSString *_UUIDString;
    BOOL _isRecordingCancel;
    AVAssetExportSession *_exportSession;
    BOOL flashMode;
    BOOL isUsedFlash;
    NSString *AVEngine_startTime;
    NSString *AVEngine_stopTime;
    
    NSString *AVEngine_startWritting;
    NSString *AVEngine_stopWritting;
    AVCaptureDeviceFormat *selectedFormat;
    AVCaptureDeviceFormat *selectedFormat_slomo;
}

@property (nonatomic, strong) AVCaptureMetadataOutput           *metadataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput              *frontCameraInput;
@property (nonatomic, weak, ) AVCaptureDeviceInput              *activeVideoInput;
@property (nonatomic, strong) AVCaptureDeviceInput              *audioMicInput;
@property (nonatomic, strong) AVCaptureDeviceFormat             *defaultFormat;
@property (nonatomic, strong) AVCaptureConnection               *audioConnection;
@property (nonatomic, strong) DLYPreviewView                    *previewView;

@property (nonatomic, strong) AVCaptureVideoDataOutput          *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput          *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput          *audioDataOutput;

@property (nonatomic, strong) dispatch_queue_t                  movieWritingQueue;
@property (nonatomic, strong) dispatch_queue_t                  dispatchQueue;

@property (nonatomic, strong) DLYMovieWriter                    *movieWriter;
@property (nonatomic, strong) AVAssetWriter                     *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput                *assetWriterAudioInput;

@property (nonatomic, strong) AVMutableComposition              *composition;
@property (nonatomic, strong) NSMutableArray                    *passThroughTimeRanges;
@property (nonatomic, strong) NSMutableArray                    *transitionTimeRanges;

@property (nonatomic, strong) AVMutableVideoComposition         *videoComposition;
@property (nonatomic, strong) AVAssetExportSession              *assetExporter;

@property (atomic, assign)    BOOL                              isCapturing;
@property (nonatomic, strong) NSMutableArray                    *imageArr;
@property (nonatomic, strong) NSTimer                           *recorderTimer;

@property (nonatomic, strong) NSString                          *currentDeviceType;

@property (nonatomic, strong) DLYResource                       *resource;
@property (nonatomic, strong) DLYSession                        *session;
@property (nonatomic, strong) DLYRecordTimer                    *recordTimer;

@property (nonatomic, assign) BOOL                              canDiscard;
@property (nonatomic, assign) DLYMiniVlogRecordType             recordType;
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
-(DLYMiniVlogVirtualPart *)currentPart{
    if (!_currentPart) {
        _currentPart = [[DLYMiniVlogVirtualPart alloc] init];
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

- (BOOL)setupCaptureSession:(NSError **)error {
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    if (![self setupCaptureSessionInputs:error]) {
        return NO;
    }
    
    if (![self setupCaptureSessionOutputs:error]) {
        return NO;
    }
    
    return YES;
}
- (BOOL)setupCaptureSessionInputs:(NSError **)error {
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if (videoInput) {
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
    if (audioInput) {
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        } else {
            return NO;
        }
    } else {
        return NO;
    }
    
    return YES;
}
- (BOOL)setupCaptureSessionOutputs:(NSError **)error {
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *outputSettings =
    @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    
    self.videoDataOutput.videoSettings = outputSettings;
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    
    [self.videoDataOutput setSampleBufferDelegate:self
                                            queue:self.dispatchQueue];
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    } else {
        return NO;
    }
    
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    [self.audioDataOutput setSampleBufferDelegate:self
                                            queue:self.dispatchQueue];
    
    if ([self.captureSession canAddOutput:self.audioDataOutput]) {
        [self.captureSession addOutput:self.audioDataOutput];
    } else {
        return NO;
    }
    
    NSString *fileType = AVFileTypeMPEG4;
    
    NSDictionary *videoSettings = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:fileType];
    
    NSDictionary *audioSettings = [self.audioDataOutput
                                   recommendedAudioSettingsForAssetWriterWithOutputFileType:fileType];
    
    self.movieWriter = [[DLYMovieWriter alloc] initWithVideoSettings:videoSettings
                                                       audioSettings:audioSettings
                                                       dispatchQueue:self.dispatchQueue];
    self.movieWriter.delegate = self;

    
    return YES;
}
- (void)startCaptureSession {
    dispatch_async(self.dispatchQueue, ^{
        if (![self.captureSession isRunning]) {
            [self.captureSession startRunning];
        }
    });
}

- (void)stopCaptureSession {
    dispatch_async(self.dispatchQueue, ^{
        if ([self.captureSession isRunning]) {
            [self.captureSession stopRunning];
        }
    });
}
- (AVCaptureDevice *)activeCamera {
    return self.activeVideoInput.device;
}

- (AVCaptureDevice *)inactiveCamera {
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1) {
        if ([self activeCamera].position == AVCaptureDevicePositionBack) {
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
            _cameraPosition = DLYAVEngineCapturePositionTypeFront;
            int32_t maxWidth = 1280;
            AVCaptureDeviceFormat *act = nil;
            for (AVCaptureDeviceFormat *format in [device formats]) {
                
                CMFormatDescriptionRef desc = format.formatDescription;
                CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                int32_t width = dimensions.width;
                
                for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                    
                    if (range.minFrameRate <= 30 && 30 <= range.maxFrameRate && width == maxWidth) {
                        act = format;
                        DLYLog(@"最终选定的正常录制格式 :format:%@", format);
                        break;
                    }
                }
                if (act) break;
            }
            if (act) {
                [self.captureSession beginConfiguration];
                if ([device lockForConfiguration:nil]) {
                    device.activeFormat = act;
                    [device unlockForConfiguration];
                }
                [self.captureSession commitConfiguration];
            }
         
        } else {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
            _cameraPosition = DLYAVEngineCapturePositionTypeBack;
        }
    }
    return device;
}
- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}

- (BOOL)switchCameras {
    
    if (![self canSwitchCameras]) {
        return NO;
    }
    
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];
    
    AVCaptureDeviceInput *videoInput =
    [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (videoInput) {
        [self.captureSession beginConfiguration];
        
        [self.captureSession removeInput:self.activeVideoInput];
        
        if ([self.captureSession canAddInput:videoInput]) {
//            [self changeCameraAnimation];
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        } else {
//            [self changeCameraAnimation];
            [self.captureSession addInput:self.activeVideoInput];
        }
        
        [self.captureSession commitConfiguration];
        
    } else {
        [self.delegate deviceConfigurationFailedWithError:error];
        return NO;
    }
    
    return YES;
}
//摄像头切换翻转动画
- (void)changeCameraAnimation {
    
    CATransition *changeAnimation = [CATransition animation];
    changeAnimation.delegate = self;
    changeAnimation.duration = 0.3;
    changeAnimation.type = @"oglFlip";
    changeAnimation.subtype = kCATransitionFromTop;
    [self.previewView.layer addAnimation:changeAnimation forKey:@"changeAnimation"];
}
-(AVCaptureSession *)captureSession{
    
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}
#pragma mark - 初始化 -
- (instancetype)initWithPreviewView:(UIView *)previewView{
    if (self = [super init]) {
        _orientation = UIDeviceOrientationLandscapeLeft;
        _dispatchQueue = dispatch_queue_create("dispatchQueue", DISPATCH_QUEUE_SERIAL);
        _previewView = previewView;
        NSError *error;
        if ([self setupCaptureSession:&error]) {
            [self startCaptureSession];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        //启动后参照中心点自动对焦一次
        [self focusContinuousWithPoint:previewView.center];
        
        //确定快慢镜头录制设备的格式
        selectedFormat = nil;
        selectedFormat_slomo = nil;
        int32_t maxWidth = 1280;
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        [device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
        if(device.isSmoothAutoFocusSupported){
            NSError *error = nil;
            if([device lockForConfiguration:&error]){
                device.smoothAutoFocusEnabled = YES;
                DLYLog(@"成功开启平滑变焦");
                [device unlockForConfiguration];
            }
        }
        for (AVCaptureDeviceFormat *format in [device formats]) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                
                if (range.minFrameRate <= 30 && 30 <= range.maxFrameRate && width == maxWidth) {
                    selectedFormat = format;
                    DLYLog(@"最终选定的正常录制格式 :format:%@", format);
                    break;
                }
                if(selectedFormat) break;
            }
            if (selectedFormat) break;
        }
        for (AVCaptureDeviceFormat *format in [device formats]) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                
                if (range.minFrameRate <= 120 && 120 <= range.maxFrameRate && width == maxWidth) {
                    selectedFormat_slomo = format;
                    DLYLog(@"最终选定的慢动作录制格式 :format:%@", format);
                    break;
                }
            }
            if (selectedFormat_slomo) break;
        }
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
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.backCameraInput];
        
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.frontCameraInput];//切换成了前置
        }
    }else {
        
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            [self changeCameraAnimation];
            [self.captureSession addInput:self.backCameraInput];//切换成了后置
        }
    }
    [self.captureSession commitConfiguration];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(device.isSmoothAutoFocusSupported){
        NSError *error = nil;
        if([device lockForConfiguration:&error]){
            device.smoothAutoFocusEnabled = YES;
            DLYLog(@"成功开启平滑变焦");
            [device unlockForConfiguration];
        }
    }
}
#pragma mark - Recorder加载组件 -
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
//元数据输出
- (AVCaptureMetadataOutput *)metadataOutput {
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
    
    NSArray *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified].devices;
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            // save the default format
            DLYLog(@"device.activeFormat:%@", device.activeFormat);
            self.defaultFormat = device.activeFormat;
            defaultVideoMaxFrameDuration = device.activeVideoMaxFrameDuration;
            defaultVideoMinFrameDuration = device.activeVideoMinFrameDuration;
            return device;
        }
    }
    return nil;
}

#pragma mark - 点触设置曝光 -

-(void)focusContinuousWithPoint:(CGPoint)point{
    //AVCaptureVideoPreviewLayer传的点是(0,0)到(1,1)之间,GLKView获得的是屏幕坐标点,需要转换
    point.x = point.x/SCREEN_WIDTH*1.0;
    point.y = point.y/SCREEN_HEIGHT*1.0;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
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
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        [captureDevice unlockForConfiguration];
        
        DLYLog(@"Current point of the capture device is :x = %f,y = %f",point.x,point.y);
    }
}
// 监听焦距发生改变
-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        
        NSLog(@"adjustingFocus~~%d  change~~%@", adjustingFocus, change);
        // 0代表焦距不发生改变 1代表焦距改变
        if (adjustingFocus == 0) {
            
       
            
            // 点击一次可能会聚一次焦，也有可能会聚两次焦。一次聚焦，图像清晰。如果聚两次焦，照片会在第二次没有聚焦完成拍照，应为第一次聚焦完成会触发拍照，而拍照时间在第二次未聚焦完成，图像不清晰。增加延时可以让每次都是聚焦完成的时间点
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [NSThread sleepForTimeInterval:0.2];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    // 拍照
                });
            });
        }
        
    }
}


#pragma mark -视频数据输出设置-

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    if (numPixels < (640 * 480) ){
        bitsPerPixel = 4.05;
    }else{
        bitsPerPixel = 11.4;
    }
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond],AVVideoAverageBitRateKey,/*
                                                [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,*/
                                               nil], AVVideoCompressionPropertiesKey,nil];
    
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }else {
            DLYLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }else {
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
    }else {
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
        }else {
            
            DLYLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }else {
        
        DLYLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        
        if ([self.assetWriter startWriting]) {
            
            DLYLog(@"AVEngine开始写入 : %@",[self getCurrentTime_MS]);
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
                    
                    DLYLog(@"isRecording:%d", self.isRecording);
                    if (self.assetWriter.error) {
                        DLYLog(@"AVAssetWriterInput video appendSampleBuffer error:%@", self.assetWriter.error);
                    }
                }
            }
        }else if (mediaType == AVMediaTypeAudio) {
            
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

#pragma mark - 改变录制帧率 -
- (void) switchRecordFormatWithRecordType:(DLYMiniVlogRecordType)recordtype
{
    dispatch_async(_dispatchQueue, ^{
        if (self.recordType ==recordtype) {
            return;
        }
        BOOL isRunning = self.captureSession.isRunning;
        if (isRunning) {
            //        [self.captureSession stopRunning];
        }
        
        _recordType = recordtype;
        AVCaptureDevice *device = self.defaultVideoDevice;
        if (recordtype == DLYMiniVlogRecordTypeSlomo) {
            DLYLog(@"慢镜头片段");
            int desiredFPS = 120;
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:self.frontCameraInput];
            if ([self.captureSession canAddInput:self.backCameraInput]) {
                [self changeCameraAnimation];
                [self.captureSession addInput:self.backCameraInput];//切换成了后置
            }
            if (selectedFormat_slomo) {
                if ([device lockForConfiguration:nil]) {
                    device.activeFormat = selectedFormat_slomo;
                    device.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
                    device.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
                    [device unlockForConfiguration];
                }
            }else{
                DLYLog(@"用默认的format :%@", selectedFormat_slomo);
                if ([device lockForConfiguration:nil]) {
                    device.activeFormat = self.defaultFormat;
                    device.activeVideoMinFrameDuration = defaultVideoMinFrameDuration;
                    device.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
                    [device unlockForConfiguration];
                }
            }
            
            [self.captureSession commitConfiguration];
        }else{
            DLYLog(@"快镜头片段或正常录制片段");
            int desiredFPS = 30;
            [self.captureSession beginConfiguration];
            
            if (selectedFormat) {
                if ([device lockForConfiguration:nil]) {
                    device.activeFormat = selectedFormat;
                    device.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
                    device.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
                    [device unlockForConfiguration];
                }
            }else{
                DLYLog(@"用默认的format :%@", selectedFormat);
                if ([device lockForConfiguration:nil]) {
                    device.activeFormat = self.defaultFormat;
                    device.activeVideoMinFrameDuration = defaultVideoMinFrameDuration;
                    device.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
                    [device unlockForConfiguration];
                }
            }
            [self.captureSession commitConfiguration];
        }
        if (isRunning) {
            //        [self.captureSession startRunning];
        }

    });

}
#pragma mark 开始录制
- (void)startRecordingWithPart:(DLYMiniVlogVirtualPart *)part{
    
    _currentPart = part;
    
    NSString *_outputPath =  [self.resource saveDraftPartWithPartNum:_currentPart.partNum];
    if (_outputPath) {
        _currentPart.partPath = _outputPath;
        DLYLog(@"第 %lu 个片段的地址 :%@",_currentPart.partNum + 1,_currentPart.partPath);
    }else{
        DLYLog(@"片段地址获取为空,直接拼出全路径");
        NSString *path = [NSString stringWithFormat:@"%@/%@/%@/part%lu%@",kPathDocument,kDataFolder,kTempFolder,(long)part.partNum,@".mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            _currentPart.partPath = path;
        }
    }
    self.movieWriter.outputUrl = [NSURL fileURLWithPath:_currentPart.partPath];
    
    DLYMiniVlogRecordType recordType = part.recordType;

    double startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
    double stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
    double duration = 0;
    switch (recordType) {
        case DLYMiniVlogRecordTypeNormal:
            duration = (stopTime - startTime);
            break;
        case DLYMiniVlogRecordTypeSlomo:
            duration = (stopTime - startTime) / 4;
            break;
        case DLYMiniVlogRecordTypeTimelapse:
            duration = (stopTime - startTime) * 4;
            break;
        default:
            break;
    }
    _recordTimer = [[DLYRecordTimer alloc] initWithPeriod:1.0f duration:duration];
    _recordTimer.timerDelegate = self;
    [_recordTimer startTick];
    
    [self.movieWriter startWritingWith:self.orientation AndCameraPosition:self.cameraPosition];
    self.isRecording = YES;
}

#pragma mark - 停止录制 -
- (void)stopRecording {
    
    [self.movieWriter stopWriting];
    self.isRecording = NO;
}

#pragma mark - 取消录制 -
- (void)cancelRecording{
    DLYLog(@"取消录制");

    self.movieWriter.isWriting = NO;
    
    dispatch_async(self.dispatchQueue, ^{
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
        }];
    });
    [_recordTimer cancelTick];
    self.isRecording = NO;

}

#pragma mark - 重置录制 -
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

#pragma mark - DLYRecordTimerDelegate -

-(void)timerAndBusinessStarted:(NSTimeInterval) time
{
    _isRecording = YES;
}

-(void)timerTicked:(NSTimeInterval) time
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(statutUpdateWithClockTick:)]) {
        [self.delegate statutUpdateWithClockTick:time];
    }
}

-(void)timerStopped:(NSTimeInterval) time
{
    [self stopRecording];
    self.isRecording = NO;
}

-(void)businessFinished:(NSTimeInterval) time;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(finishedRecording)]) {
        [self.delegate finishedRecording];
    }
}

-(void)timerCanceled:(NSTimeInterval) time
{

}

-(void)businessCanceled:(NSTimeInterval) time
{

}

#pragma mark - 视频速度处理 -
- (void)setSpeedWithVideo:(NSURL *)videoPartUrl outputUrl:(NSURL *)outputUrl soundType:(DLYMiniVlogAudioType)soundType recordTypeOfPart:(DLYMiniVlogRecordType)recordType completed:(void(^)())completed {
    
    DLYLog(@"调节视频速度...");
    // 获取视频
    if (!videoPartUrl) {
        DLYLog(@"待调速的视频片段不存在!");
        return;
    }else{
        
        Float64 scale = 0;
        if(recordType == DLYMiniVlogRecordTypeTimelapse){
            scale = 0.25f;  // 0.25对应  快速 x4   播放时间压缩帧率平均(低帧率)
        } else if (recordType == DLYMiniVlogRecordTypeSlomo) {
            scale = 4.0f;  //  4.0对应  慢速 x4   播放时间拉长帧率平均(高帧率)
        }else{
            scale = 1.0f;
        }
        AVURLAsset *videoAsset = nil;
        if(videoPartUrl) {
            videoAsset = [[AVURLAsset alloc]initWithURL:videoPartUrl options:nil];
        }
        
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale));

        if (soundType == DLYMiniVlogAudioTypeNarrate) {

            AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            [compositionVideoTrack insertTimeRange:videoTimeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
            [compositionAudioTrack insertTimeRange:videoTimeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];

        }else if (soundType == DLYMiniVlogAudioTypeMusic){//不录音的片段做丢弃原始音频处理
            
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
            
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale));
            
            CMTime toDuration_after = CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale);
            
            [compositionVideoTrack scaleTimeRange:timeRange toDuration:toDuration_after];
        }
        
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = outputUrl;
        assetExport.shouldOptimizeForNetworkUse = YES;
        [assetExport exportAsynchronouslyWithCompletionHandler:^{
            completed();
        }];
    }
}

#pragma mark -添加片头片尾-
- (void)addVideoHeaderWithTitle:(NSString *)videoTitle successed:(SuccessBlock)successBlock failured:(FailureBlock)failureBlcok{

    if (self.session.currentTemplate.videoHeaderType == DLYMiniVlogHeaderTypeNone) {
        [self mergeVideoWithVideoTitle:videoTitle successed:^{
            //成功
            successBlock();
        } failured:^(NSError *error) {
            //
            failureBlcok(error);
        }];
        return;
    }
    NSURL *headerUrl;
    NSURL *footerUrl;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            NSString *headerPath = @"";
            if (draftArray.count!=0) {
                headerPath = @"part0.mp4";
            }
            if ([headerPath hasSuffix:@"mp4"]) {
                NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",headerPath];
                headerUrl = [NSURL fileURLWithPath:allPath];
            }
            NSString *footerPath = @"";
            if (draftArray.count!=0) {
                footerPath =[NSString stringWithFormat:@"part%ld.mp4",draftArray.count-1-1];
            }
            
            if ([footerPath hasSuffix:@"mp4"]) {
                NSString *allPath = [draftPath stringByAppendingFormat:@"/%@",footerPath];
                footerUrl = [NSURL fileURLWithPath:allPath];
            }
        }
    }
    
    [self addVideoEffectsWithHeaderUrl:headerUrl andFooterUrl:footerUrl withTitle:videoTitle];
}

- (void)addVideoEffectsWithHeaderUrl:(NSURL *)headerUrl andFooterUrl:(NSURL *)footerUrl withTitle:(NSString *)title  {
    
    BOOL isAudio = NO;
    
    NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
    
    NSMutableArray *headArray = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        for (int i = 20; i < 124; i++)
        {
            @autoreleasepool {
                NSString *imageName = [NSString stringWithFormat:@"MyHeader1_00%03d.png", i];
                UIImage *image = [UIImage imageNamed:imageName];
                UIImage *newImage = [image scaleToSize:CGSizeMake(600, 600)];
                [headArray addObject:(id)newImage.CGImage];
//                DLYLog(@"片头图片:%zd", headArray.count);
            }
        }
        [weakSelf buildVideoEffectsToMP4:headerPath inputVideoURL:headerUrl andImageArray:headArray andBeginTime:0.1 isAudio:isAudio callback:^(NSURL *finalUrl, NSString *filePath) {
//            DLYLog(@"片头完成");
            
            NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
            NSMutableArray *footArray = [NSMutableArray array];
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(queue, ^{
                
                for (int i = 15; i<210; i++)
                {
                    @autoreleasepool {
                        NSString *imageName = [NSString stringWithFormat:@"MyFooter1_00%03d.png", i];
                        UIImage *image = [UIImage imageNamed:imageName];
                        UIImage *newImage = [image scaleToSize:CGSizeMake(600, 600)];
                        [footArray addObject:(id)newImage.CGImage];
//                        DLYLog(@"片尾图片:%zd", footArray.count);
                    }
                }
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:footerUrl options:nil];
                Float64 timeSeconds = CMTimeGetSeconds(asset.duration);
                float beginTime;
                if (timeSeconds > 2.2) {
                    beginTime = (float)timeSeconds - 2.2;
                }else{
                    beginTime = 0.1;
                }
                [weakSelf buildVideoEffectsToMP4:footerPath inputVideoURL:footerUrl andImageArray:footArray andBeginTime:beginTime isAudio:isAudio callback:^(NSURL *finalUrl, NSString *filePath) {
//                    DLYLog(@"片尾完成");
                    [weakSelf mergeVideoWithVideoTitle:title successed:^{
                        //成功
                    } failured:^(NSError *error) {
                        //
                    }];
                }];
            });
        }];
    });
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (captureOutput == self.videoDataOutput) {
        BOOL ifProcess = NO;
        if (self.recordType == DLYMiniVlogRecordTypeSlomo) {
            self.canDiscard = !self.canDiscard;
            ifProcess = !self.canDiscard;
        }else{
            ifProcess = YES;
        }
        if (ifProcess) {
            CVPixelBufferRef imageBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer);
            
            CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer options:nil];
            [self.previewView setImage:sourceImage];
        }
        [self.movieWriter processVideoSampleBuffer:sampleBuffer];


    }else if(captureOutput == self.audioDataOutput){
        [self.movieWriter processAudioSampleBuffer:sampleBuffer];

    }
}
-(void)didWriteMovieAtURL:(NSURL *)outputURL{
    //导出保存
    [self saveRecordedFile];
}
#pragma mark 从输出的元数据中捕捉人脸

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{

    if (NEW_FUNCTION) {
        if (_isSupportFaceReconginition) {
            if (metadataObjects.count) {
                
                AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
                AVMetadataObject *transformedMetadataObject = [self.captureVideoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObject];
                
                faceRegion = transformedMetadataObject.bounds;
                
                if (metadataObject.type != AVMetadataObjectTypeFace)
                    faceRegion = CGRectZero;
            }else{
                faceRegion = CGRectZero;
            }
        }
    }
}
#pragma mark - 人脸识别用定时器 -

NSInteger timeCount = 0;
NSInteger maskCount = 0;
NSInteger startCount = MAXFLOAT;
BOOL isOnce = YES;

- (void)createFaceRecognitionTimer{

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t enliveTime2 = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC);

    dispatch_source_set_timer(enliveTime2, start, interval, 0);

    dispatch_source_set_event_handler(enliveTime2, ^{

        CGFloat distance = distanceBetweenPoints(faceRegion.origin, lastFaceRegion.origin);
        lastFaceRegion = faceRegion;
        if (distance < 20) {
            if (isOnce) {
                isOnce = NO;
//                CGPoint point = CGPointMake(faceRegion.size.width/2, faceRegion.size.height/2);
//                CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
//                [self focusContinuousWithPoint:cameraPoint];
                startCount = timeCount;
            }
            maskCount++;
        }
        timeCount++;
        if (timeCount - startCount >= 1) {
            if (maskCount == 1) {
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
            dispatch_cancel(enliveTime2);
        }

    });
    //启动定时器
    dispatch_resume(enliveTime2);
}
#pragma mark - 视频取帧 -
-(UIImage*)getKeyImage:(NSURL *)assetUrl intervalTime:(Float32)intervalTime{
    
    CMTime keyTime = CMTimeMakeWithSeconds(intervalTime,30);
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
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:keyTime actualTime:NULL error:&thumbnailImageGenerationError];
    
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
    NSString *partsPath;
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        NSString *virtualPartPath = [draftPath stringByAppendingPathComponent:kVirtualFolder];
        if (![[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
            
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:virtualPartPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:virtualPartPath withIntermediateDirectories:YES attributes:nil error:nil];

        }

        exportPath = [NSString stringWithFormat:@"%@/part%lu.mp4",virtualPartPath,(long)_currentPart.partNum];
        partsPath = [NSString stringWithFormat:@"%@/part%lu.mp4",draftPath,(long)_currentPart.partNum];
    }
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DLYIndicatorView sharedIndicatorView] startFlashAnimatingWithTitle:@"处理中,请稍后"];
        typeof(self) weakSelf = self;
        [weakSelf setSpeedWithVideo:[NSURL fileURLWithPath:_currentPart.partPath] outputUrl:exportUrl soundType:_currentPart.soundType recordTypeOfPart:_currentPart.recordType completed:^{
            DLYLog(@"第 %lu 个片段调速完成",self.currentPart.partNum + 1);
            [self.resource removePartWithPartNumFormTemp:self.currentPart.partNum];
            //如果是需要拍摄的且需要切分
            if (self.currentPart.partsInfo.count>1){
                double lastDuration = 0;
                for (DLYMiniVlogPart *part in self.currentPart.partsInfo) {
                    NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
                    NSString *trimPartPath = [NSString stringWithFormat:@"%@/part%lu.mp4",draftPath,(long)part.partNum];
                    double startTime = [self getTimeWithString:part.dubStartTime];
                    double stopTime = [self getTimeWithString:part.dubStopTime];
                    [self trimVideoByWithUrl:exportUrl outputUrl:[NSURL fileURLWithPath:trimPartPath] startTime:lastDuration duration:stopTime-startTime];
                    lastDuration = stopTime - startTime;
                }
                NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];

                for (DLYMiniVlogPart * part in self.session.currentTemplate.parts) {

                    if (part.partType ==DLYMiniVlogPartTypeComputer) {
                        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:[part partPath] ofType:nil];
                        NSString *destPath = [NSString stringWithFormat:@"%@/part%ld.mp4",draftPath,[part partNum]];
                        NSError *error;
                        
                        [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:destPath error:nil];
                        if (error) {
                            DLYLog(@"bundle路径拷贝到parts路径失败，原因：%@",error);
                        }
                    }
                }
                
            }else{
                NSError *error;
//                [[NSFileManager defaultManager] createSymbolicLinkAtPath:partsPath withDestinationPath:exportPath error:&error];
                [[NSFileManager defaultManager] copyItemAtPath:exportPath toPath:partsPath error:&error];
                if (error) {
                    DLYLog(@"virtual路径拷贝到parts路径失败，原因：%@",error);
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
            });
        }];
    });
}

#pragma mark - 合并 -
- (void) mergeVideoWithVideoTitle:(NSString *)videoTitle successed:(SuccessBlock)successBlock failured:(FailureBlock)failureBlcok{
    
    BOOL isCreateAudioTrack = NO;
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    
    NSMutableArray *videoArray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if ([[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
            
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            BOOL isEmpty = YES;
            int partNum = 0;
            for (NSInteger i = 0; i < [draftArray count]; i++) {
                NSString *path = draftArray[i];
                DLYLog(@"合并-->加载--> 第 %lu 个片段",i);
                if ([path hasSuffix:@"mp4"]) {
                    isEmpty = NO;
                    NSString *allPath = [draftPath stringByAppendingFormat:@"/part%d.mp4",partNum++];
                    NSURL *url= [NSURL fileURLWithPath:allPath];
                    
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
                    if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
                        isCreateAudioTrack = YES;
                    }
                    [videoArray addObject:url];
                }
            }
            if (isEmpty){
                BOOL needCombine = NO;
                for (DLYMiniVlogPart *part in self.session.currentTemplate.parts) {
                    if (part.ifCombin) {
                        needCombine = YES;
                        break;
                    }
                }
#warning 目前是10s只会拍摄一次 存在视频切分异步问题
                if (needCombine){
                    NSString *exportPath = @"";
                    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
                        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
                        NSString *virtualPartPath = [draftPath stringByAppendingPathComponent:kVirtualFolder];
                        if (![[NSFileManager defaultManager] fileExistsAtPath:draftPath]) {
                            [[NSFileManager defaultManager] createDirectoryAtPath:draftPath withIntermediateDirectories:YES attributes:nil error:nil];
                            
                        }
                        if (![[NSFileManager defaultManager] fileExistsAtPath:virtualPartPath]) {
                            [[NSFileManager defaultManager] createDirectoryAtPath:virtualPartPath withIntermediateDirectories:YES attributes:nil error:nil];
                            
                        }
                        
                        exportPath = [NSString stringWithFormat:@"%@/part%lu.mp4",virtualPartPath,(long)_currentPart.partNum];
                    }
                    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
                    if (self.session.currentTemplate.virtualParts<=0){
                        DLYLog(@"草稿有合拍的视频但没有切分且读取不到当前模板的虚拟片段");
                        return;
                    }
                    if (self.session.currentTemplate.virtualParts[0].partsInfo.count>1){
                        double lastDuration = 0;
                        for (DLYMiniVlogPart *part in self.self.session.currentTemplate.virtualParts[0].partsInfo) {
                            
                            NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
                            NSString *trimPartPath = [NSString stringWithFormat:@"%@/part%lu.mp4",draftPath,(long)part.partNum];
                            double startTime = [self getTimeWithString:part.dubStartTime];
                            double stopTime = [self getTimeWithString:part.dubStopTime];
                            [self trimVideoByWithUrl:exportUrl outputUrl:[NSURL fileURLWithPath:trimPartPath] startTime:lastDuration duration:stopTime-startTime];
                            lastDuration = stopTime - startTime;
                        }
                        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
                        
                        for (DLYMiniVlogPart * part in self.session.currentTemplate.parts) {
                            
                            if (part.partType ==DLYMiniVlogPartTypeComputer) {
                                NSString *bundlePath = [[NSBundle mainBundle] pathForResource:[part partPath] ofType:nil];
                                NSString *destPath = [NSString stringWithFormat:@"%@/part%ld.mp4",draftPath,[part partNum]];
                                NSError *error;
                                
                                [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:destPath error:nil];
                                if (error) {
                                    DLYLog(@"bundle路径拷贝到parts路径失败，原因：%@",error);
                                }
                            }
                        }
                        
                    }
                    NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
                    for (NSInteger i = 0; i < [draftArray count]; i++) {
                        NSString *path = draftArray[i];
                        DLYLog(@"合并-->加载--> 第 %lu 个片段",i);
                        if ([path hasSuffix:@"mp4"]) {
                            NSString *allPath = [draftPath stringByAppendingFormat:@"/part%d.mp4",partNum++];
                            NSURL *url= [NSURL fileURLWithPath:allPath];
                            [videoArray addObject:url];
                        }
                    }
                }
            }
        }
    }
    DLYLog(@"待合成的视频片段: %@",videoArray);
    
    CMTime cursorTime = kCMTimeZero;
    BOOL containCombin = NO;
    for (DLYMiniVlogVirtualPart *part in self.session.currentTemplate.virtualParts) {
        if(part.partsInfo.count>1){
            containCombin = YES;
        }
    }
    for (NSUInteger i = 0; i < videoArray.count; i++) {
        
        AVURLAsset *asset = nil;
       
        if (self.session.currentTemplate.videoHeaderType ==DLYMiniVlogHeaderTypeNone){
            asset = [AVURLAsset URLAssetWithURL:videoArray[i] options:nil];
        }else{
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
        }
       
        
        AVAssetTrack *assetVideoTrack = nil;
        AVAssetTrack *assetAudioTrack = nil;
        
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
        
        AVMutableCompositionTrack *compositionAudioTrack = nil;
        if (isCreateAudioTrack) {
            compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
            
            NSError *audioError = nil;
            [compositionAudioTrack insertTimeRange:timeRange ofTrack:assetAudioTrack atTime:cursorTime error:&audioError];
            if (audioError) {
                DLYLog(@"视频合成过程音频轨道插入发生错误,错误信息 :%@",audioError);
            }
        }

        cursorTime = CMTimeAdd(cursorTime, timeRange.duration);
    }
    
    NSURL *productOutputUrl = nil;
    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
        
        _UUIDString = [self.resource stringWithUUID];
        NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",productPath,_UUIDString];
        if (outputPath) {
            productOutputUrl = [NSURL fileURLWithPath:outputPath];
        }else{
            DLYLog(@"合并视频保存地址获取失败 !");
        }
    }
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1280x720];
    assetExportSession.outputURL = productOutputUrl;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"全部片段merge成功");
        if (APPTEST) {
            UISaveVideoAtPathToSavedPhotosAlbum([productOutputUrl path], self, nil, nil);
        }
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@"m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        [self addMusicToVideo:productOutputUrl audioUrl:BGMUrl videoTitle:videoTitle successed:successBlock failured:failureBlcok];
    }];
}
#pragma mark - 媒体文件截取 -
-(void)trimVideoByWithUrl:(NSURL *)assetUrl outputUrl:(NSURL *)outputUrl startTime:(double)startTime duration:(double)duration{
    
    AVAsset *asset = [AVAsset assetWithURL:assetUrl];
    AVAssetTrack *videoAssertTrack = nil;
    AVAssetTrack *audioAssertTrack = nil;
    
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        videoAssertTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    }
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0){
        audioAssertTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    }
  
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    CMTime _startTime = CMTimeMakeWithSeconds(startTime / 1000, asset.duration.timescale);
    CMTime _duration = CMTimeMakeWithSeconds(duration / 1000, asset.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(_startTime,_duration);
    
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:videoAssertTrack atTime:kCMTimeZero error:nil];
//    [audioCompositionTrack insertTimeRange:videoTimeRange ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPreset1280x720];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:outputUrl.path]) {
        [[NSFileManager defaultManager]removeItemAtPath:outputUrl.path error:nil];
    }
    exportSession.outputURL = outputUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"视频截取成功");
    }];
}
#pragma mark - 转场 -
- (void) addTransitionEffectWithTitle:(NSString *)videoTitle  successed:(SuccessBlock)successBlock failured:(FailureBlock)failureBlcok{
    
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
                DLYLog(@"合并-->加载--> 第 %lu 个片段",i);
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
        
        NSError *videoInsertError = nil;
        BOOL isInsertVideoSuccess = [currentVideoTrack insertTimeRange:timeRange
                                                          ofTrack:assetVideoTrack
                                                           atTime:videoCursorTime error:&videoInsertError];
        if (isInsertVideoSuccess == NO) {
            DLYLog(@"合并时插入图像轨失败 - %@",videoInsertError);
        }
        
        NSError *audioInsertError = nil;
        BOOL isInsertAudioSuccess = [currentAudioTrack insertTimeRange:timeRange
                                                                   ofTrack:assetAudioTrack
                                                                    atTime:videoCursorTime error:&audioInsertError];
        if (isInsertAudioSuccess == NO) {
            DLYLog(@"合并时插入音轨失败 - %@",audioInsertError);
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
        
        _UUIDString = [self.resource stringWithUUID];
        NSString *outputPath = [NSString stringWithFormat:@"%@/%@.mp4",productPath,_UUIDString];
        if (outputPath) {
            productOutputUrl = [NSURL fileURLWithPath:outputPath];
        }else{
            DLYLog(@"合并视频保存地址获取失败 !");
        }
    }
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPreset1280x720];
    assetExportSession.videoComposition = videoComposition;
    assetExportSession.outputURL = productOutputUrl;
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        DLYLog(@"全部片段merge成功");
        DLYMiniVlogTemplate *template = self.session.currentTemplate;
        
        NSString *BGMPath = [[NSBundle mainBundle] pathForResource:template.BGM ofType:@"m4a"];
        NSURL *BGMUrl = [NSURL fileURLWithPath:BGMPath];
        [self addMusicToVideo:productOutputUrl audioUrl:BGMUrl videoTitle:videoTitle successed:successBlock failured:failureBlcok];
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
        DLYLog(@"videoWidth: %f,videoHeight: %f",videoWidth,videoHeight);
        
        //Transform
        CGAffineTransform fromDestTransform = CGAffineTransformMakeTranslation(-videoWidth, 0.0);
        CGAffineTransform toStartTransform = CGAffineTransformMakeTranslation(videoWidth, 0.0);
        
        CGAffineTransform transform1 = CGAffineTransformMakeRotation(M_PI);
        CGAffineTransform transform2 = CGAffineTransformScale(transform1, 2.0, 2.0);
        
        //Rotation
        CGAffineTransform fromDestTransformRotation = CGAffineTransformMakeRotation(-M_PI);
        CGAffineTransform toStartTransformRotation = CGAffineTransformMakeRotation(M_PI);
        
        //Scale
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
- (NSArray *)transitionInstructionsInVideoComposition:(AVVideoComposition *)videoComposition {
    
    NSMutableArray *transitionInstructions = [NSMutableArray array];
    
    int layerInstructionIndex = 1;
    
    NSArray *compositionInstructions = videoComposition.instructions;
    
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
#pragma mark - 双音轨合成控制 -
- (void) addMusicToVideo:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl videoTitle:(NSString *)videoTitle successed:(SuccessBlock)success failured:(FailureBlock)failureBlcok{
    
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:audioUrl options:nil];
    
    AVAssetTrack *videoAssetTrack = nil;
    if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    
    //BGM音频素材
    AVAssetTrack *BGMAudioAssetTrack = nil;
    if ([[audioAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        BGMAudioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:trackID];
    AVMutableCompositionTrack *BGMAudioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:trackID];
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero,audioAsset.duration);
    
    NSError *error = nil;
    if (videoAssetTrack) {
        [videoCompositionTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    }
    //BGM音轨
    if (BGMAudioAssetTrack) {
        [BGMAudioCompositionTrack insertTimeRange:audioTimeRange ofTrack:BGMAudioAssetTrack atTime:kCMTimeZero error:&error];
    }
    
    [videoCompositionTrack setPreferredTransform:videoAssetTrack.preferredTransform];
    
    //拿到视频原声音轨
    AVAssetTrack *originalAudioAssetTrack = nil;
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        originalAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    }
    
    AVMutableCompositionTrack *originalAudioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //添加标题
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];

    if ([[mixComposition tracksWithMediaType:AVMediaTypeVideo] count] != 0) {

        videoComposition.frameDuration = CMTimeMake(1, 30);
        videoComposition.renderSize = videoAssetTrack.naturalSize;
        
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);

        AVAssetTrack *videoTrack = [mixComposition tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

        passThroughInstruction.layerInstructions = @[passThroughLayer];
        videoComposition.instructions = @[passThroughInstruction];

        CGSize renderSize = videoComposition.renderSize;
        
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        
        CALayer *videoTitleLayer = [self addTitleForVideoWith:videoTitle size:renderSize];
        videoTitleLayer.position = CGPointMake(renderSize.width / 2,renderSize.height / 2);
        [parentLayer addSublayer:videoTitleLayer];
        
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        [parentLayer addSublayer:videoLayer];
        
//        if (APPTEST) {
//            CALayer *watermarkLayer = [self addTestInfoWatermarkWithSize:renderSize];
//            watermarkLayer.position = CGPointMake(renderSize.width - watermarkLayer.bounds.size.width / 2, 15);
//            [parentLayer addSublayer:watermarkLayer];
//        }

        //添加视频边框
        if (self.session.currentTemplate.renderBorderName) {
            //边框
            UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, renderSize.width, renderSize.height)];
            imageView.image = [UIImage imageNamed:self.session.currentTemplate.renderBorderName];
            
            CALayer *videoBorderLayer = [CALayer layer];
            videoBorderLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
            [videoBorderLayer addSublayer:imageView.layer];
            [parentLayer addSublayer:videoBorderLayer];
            
            //时间戳
            NSInteger days = [self getTodayIsHowManyDay];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy"];
            NSString *whichYear = [formatter stringFromDate:[NSDate date]];
            NSString *daysMessage = [NSString stringWithFormat:@"%@ NO.%lu",whichYear,days];
            NSDictionary *dateWaterMarkDict =self.session.currentTemplate.dateWaterMark ;
            NSString *fontName = [dateWaterMarkDict valueForKey:@"fontName"];
            int fontSize = [[dateWaterMarkDict valueForKey:@"size"] integerValue]*renderSize.height/1080;
            int wordSpace = [[dateWaterMarkDict valueForKey:@"wordSpace"] integerValue]/30.0;
            NSString* textColor = [dateWaterMarkDict valueForKey:@"color"];
            UIColor *co = [UIColor colorWithHexString:textColor];
            NSDictionary *attributes = @{NSKernAttributeName:@(wordSpace),NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize],NSForegroundColorAttributeName:[UIColor colorWithHexString:textColor withAlpha:1]};
            NSAttributedString *attibutedString = [[NSAttributedString alloc]initWithString:daysMessage attributes:attributes];
            
            CGSize textSize = [daysMessage sizeWithAttributes:attributes];
            
            CATextLayer *daysLayer = [CATextLayer layer];
//            daysLayer.frame = CGRectMake(0, 0, textSize.width * 1.6, textSize.height * 1.05);
            daysLayer.frame = CGRectMake(0, 0, textSize.width, textSize.height);
            [daysLayer setString:attibutedString];
            [daysLayer setAlignmentMode:kCAAlignmentCenter];
//            [daysLayer setForegroundColor:[[UIColor colorWithHexString:textColor withAlpha:1] CGColor]];
            daysLayer.position = CGPointMake((renderSize.width - textSize.width / 2), 35);
            
            CGFloat pointX =renderSize.width*[[dateWaterMarkDict valueForKey:@"x"] floatValue]/1920+textSize.width/2;
            CGFloat pointY =renderSize.height- renderSize.height*[[dateWaterMarkDict valueForKey:@"y"] floatValue]/1080-textSize.height/2;
            daysLayer.position = CGPointMake(pointX, pointY);
            [parentLayer addSublayer:daysLayer];
            
            //POWERED BY 一分
//            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//            NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//            NSString *maskStr = [NSString stringWithFormat:@"POWERED BY %@",app_Name];
//
//            UIFont *maskStrfFont = [UIFont fontWithName:@"Helvetica" size:20];
//            CGSize maskStrTextSize = [maskStr sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:maskStrfFont,NSFontAttributeName, nil]];
//
//            CATextLayer *markStrLayer = [CATextLayer layer];
//            markStrLayer.frame = CGRectMake(0, 0, maskStrTextSize.width, maskStrTextSize.height);
//            markStrLayer.position = CGPointMake(renderSize.width - markStrLayer.bounds.size.width / 2 - 10, 90);
//            [markStrLayer setFontSize:20.f];
//            [markStrLayer setString:maskStr];
//            [markStrLayer setFont:@"Helvetica"];
//            [markStrLayer setAlignmentMode:kCAAlignmentCenter];
//            [markStrLayer setForegroundColor:[[UIColor colorWithHexString:@"#ffffff" withAlpha:0.5] CGColor]];
//            [parentLayer addSublayer:markStrLayer];
        }

        videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }

    [originalAudioCompositionTrack insertTimeRange:originalAudioAssetTrack.timeRange ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    AVMutableAudioMixInputParameters *videoParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:originalAudioCompositionTrack];
    AVMutableAudioMixInputParameters *BGMParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:BGMAudioCompositionTrack];
    
    NSArray *partArray = self.session.currentTemplate.parts;

    for (NSInteger i = 0; i < partArray.count; i++) {

        DLYMiniVlogPart *part = partArray[i];

        double startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
        double stopTime = [self getTimeWithString:part.dubStopTime] / 1000;

        _startTime = CMTimeMakeWithSeconds(startTime, audioAsset.duration.timescale);
        _stopTime = CMTimeMakeWithSeconds(stopTime, audioAsset.duration.timescale);

        CMTime duration = CMTimeSubtract(_stopTime, _startTime);
        CMTimeRange timeRange = CMTimeRangeMake(_startTime, duration);
        [BGMParameters setVolumeRampFromStartVolume:part.BGMVolume / 100 toEndVolume:part.BGMVolume / 100 timeRange:timeRange];
    }
    audioMix.inputParameters = @[videoParameters,BGMParameters];
    
    NSURL *outPutUrl = [self.resource saveProductToSandbox];
    self.currentProductUrl = outPutUrl;
    
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
    assetExportSession.outputURL = outPutUrl;
    assetExportSession.audioMix = audioMix;
    assetExportSession.videoComposition = videoComposition;
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
                
                DLYPhotoAlbum *phoneAlbum = [[DLYPhotoAlbum alloc] init];

                [phoneAlbum saveVideoToAlbumWithUrl:outPutUrl allbumName:@"一分" successed:^{
                    DLYLog(@"保存成功");
                    BOOL isSuccess = NO;
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    
                    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
                    NSString *productPath = [dataPath stringByAppendingPathComponent:kProductFolder];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:productPath]) {
                        
                        NSString *targetPath = [productPath stringByAppendingFormat:@"/%@.mp4",_UUIDString];
                        isSuccess = [fileManager removeItemAtPath:targetPath error:nil];
                        DLYLog(@"%@",isSuccess ? @"成功删除未配音的成片视频 !" : @"删除未配音视频失败");
                    }
                    
                    NSString *headerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"headerVideo.mp4"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                        isSuccess = [fileManager removeItemAtPath:headerPath error:nil];
                        DLYLog(@"删除片头");
                    }
                    
                    NSString *footerPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"footerVideo.mp4"];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:footerPath]) {
                        isSuccess = [fileManager removeItemAtPath:footerPath error:nil];
                        DLYLog(@"删除片尾");
                    }
                    success();
                } failured:^(NSError *error) {
                    DLYLog(@"保存失败");
                    failureBlcok(error);
                }];
            }break;
            default:
                break;
        }
    }];
}
#pragma mark - 添加测试水印 -
- (CALayer *) addTestInfoWatermarkWithSize:(CGSize)renderSize
{
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
    UIFont *font = [UIFont systemFontOfSize:24.0];
    CGSize textSize = [watermarkMessage sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    
    CATextLayer *watermarkLayer = [CATextLayer layer];
    watermarkLayer.frame = CGRectMake(0, 0, textSize.width * 1.14, textSize.height * 1.05);

    [watermarkLayer setFontSize:24.f];
    [watermarkLayer setFont:@"ArialRoundedMTBold"];
    [watermarkLayer setString:watermarkMessage];
    [watermarkLayer setAlignmentMode:kCAAlignmentCenter];
    [watermarkLayer setForegroundColor:[[UIColor colorWithHexString:@"FFFFFF" withAlpha:1] CGColor]];
    [watermarkLayer setBackgroundColor:[[UIColor colorWithHexString:@"#000000" withAlpha:0.8] CGColor]];
    return watermarkLayer;
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

#pragma mark - 动态水印
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoURL:(NSURL *)inputVideoURL andImageArray:(NSMutableArray *)imageArr andBeginTime:(float)beginTime isAudio:(BOOL)isAudio callback:(Callback )callBlock{
    
    // 1.
    if (!inputVideoURL || ![inputVideoURL isFileURL] || !exportVideoFile || [exportVideoFile isEqualToString:@""]) {
        DLYLog(@"Input filename or Output filename is invalied for convert to Mp4!");
        return NO;
    }
    
    unlink([exportVideoFile UTF8String]);
    
    // 2. Create the composition and tracks
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
    NSParameterAssert(asset);
    if(asset ==nil || [[asset tracksWithMediaType:AVMediaTypeVideo] count]<1) {
        DLYLog(@"Input video is invalid!");
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
            
            DLYLog(@"Error reading the transformed video track");
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
            DLYLog(@"Reminder: video hasn't audio!");
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
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
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
    NSURL *exportUrl = [NSURL fileURLWithPath:[exportPath stringByReplacingOccurrencesOfString:@" " withString:@" "]];
    
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
                    
                    DLYLog(@"MP4 Successful!");
                    callBlock(exportUrl,exportPath);
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    DLYLog(@"导出失败");
                    callBlock(exportUrl,exportPath);
                    
                });
                
                DLYLog(@"Export failed: %@", [[_exportSession error] localizedDescription]);
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                DLYLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                DLYLog(@"Export Waiting");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                DLYLog(@"Export Exporting");
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
    animationLayer.frame = CGRectMake(0, 0, 1280, 720);
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
- (double)getTimeWithString:(NSString *)timeString
{
    NSArray *stringArr = [timeString componentsSeparatedByString:@":"];
    NSString *timeStr_M = stringArr[0];
    NSString *timeStr_S = stringArr[1];
    NSString *timeStr_MS = stringArr[2];
    
    double timeNum_M = [timeStr_M doubleValue] * 60 * 1000;
    double timeNum_S = [timeStr_S doubleValue] * 1000;
    double timeNum_MS = [timeStr_MS doubleValue] * 10;
    double timeNum = timeNum_M + timeNum_S + timeNum_MS;
    return timeNum;
}

- (long long)getDateTimeTOMilliSeconds:(NSDate *)datetime {
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval * 1000;
    return totalMilliseconds;
}
#pragma mark - 获取当地当前时间 -

- (NSString *)getCurrentTime_MS {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}
- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy.MM.dd  HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

- (NSInteger) getTodayIsHowManyDay
{
    NSDate*date = [NSDate date];
    NSCalendar*calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:(NSWeekCalendarUnit | NSWeekdayCalendarUnit |NSWeekdayOrdinalCalendarUnit)fromDate:date];
    
    NSInteger week = [comps week];
    NSInteger weekday = [comps weekday];
    
    NSInteger howManyDay = (week - 1) * 7 + weekday;
    
    return howManyDay;
}

//计算两点间距离
CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY);
};

@end

