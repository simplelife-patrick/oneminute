//
//  AVManager.m
//  AVEngineDemo
//
//  Created by APPLE on 2017/11/16.
//  Copyright © 2017年 LDJ. All rights reserved.
//

#import "AVManager.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AVManager()< AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t movieWritingQueue;
    
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;

    CMBufferQueueRef previewBufferQueue;
    BOOL recordingWillBeStarted;
    BOOL videoHasRecorded;
}

@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, copy) NSString *finalPath;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层

// for video data output
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic ,strong)dispatch_source_t timer;
@property (nonatomic, assign)NSInteger duration;//录制时长


@end

@implementation AVManager


- (instancetype)initWithPreviewView:(UIView *)previewView {
    
    self = [super init];
    
    if (self) {
        _scale = 1;
        _session = [[AVCaptureSession alloc]init];
        //分辨率
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [_session setSessionPreset:AVCaptureSessionPresetHigh];
        }
        //设备handle
        AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        //device input
        NSError *error;
        AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:cameraDevice error:&error];
        if (error) {
            NSLog(@"getting video device input has failed,%@",error);
        }
        _captureDeviceInput = videoInput;
        AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
        if (error) {
            NSLog(@"getting audio device input has failed,%@",error);
        }
    
        //添加device input
        if ([_session canAddInput:videoInput]) {
            [_session addInput:videoInput];
        }else{
            NSLog(@"Session can not add video input");
        }
        if ([_session canAddInput:audioInput]) {
            [_session addInput:audioInput];
        }{
            NSLog(@"Session can not add audio input");
        }
        //输出实例
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        //添加输出实例
        if ([_session canAddOutput:videoDataOutput]) {
            [_session addOutput:videoDataOutput];
        }else{
            NSLog(@"Session can not add video output");
        }
        [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        movieWritingQueue = dispatch_queue_create("com.LDJ.AVEngineDemo.movieWritingQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t videoCaptureQueue = dispatch_queue_create("com.LDJ.AVEngineDemo.videoCaptureQueue", NULL);
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
        self.videoConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
//        self.videoConnection.videoScaleAndCropFactor = 
        
        // Audio
        AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        if ([_session canAddOutput:audioDataOutput]) {
            [self.session addOutput:audioDataOutput];
        }else{
            NSLog(@"Session can not add audio output");
        }
        
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create("com.LDJ.AVEngineDemo.audioCaptureQueue", DISPATCH_QUEUE_SERIAL);
        [audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
        
        self.audioConnection = [audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
        OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
        NSLog(@"CMBufferQueueCreate error:%d", err);
        //预览层
        AVCaptureVideoPreviewLayer* captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        CALayer *layer = previewView.layer;
        layer.masksToBounds = YES;
        captureVideoPreviewLayer.frame = layer.bounds;
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [layer insertSublayer:captureVideoPreviewLayer atIndex:0];;
        [_session startRunning];
    }
    return self;
}
- (void)startRecordVideoWithDuration:(NSInteger)durationMS AndScale:(double)scale{
    _duration = durationMS;
    _scale = scale;
    if (scale >1) {
        [self changeFPS:scale * 30];
    }
    [self startRecordVideo];
}
-(void)changeFPS:(CGFloat)desiredFPS{
    BOOL isRunning = self.session.isRunning;
    
    if (isRunning)  [self.session stopRunning];
    
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
    
    if (selectedFormat) {
        
        if ([videoDevice lockForConfiguration:nil]) {
            
            NSLog(@"selected format:%@", selectedFormat);
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [videoDevice unlockForConfiguration];
        }
    }
    
    if (isRunning) [self.session startRunning];
}

- (void)startRecordVideo
{


    _finalPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"final.mov"];
    NSError *error;
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:_finalPath]) {
        [[NSFileManager defaultManager]removeItemAtPath:_finalPath error:&error];
        if (error) {
            NSLog(@"%@",error);
        }
    }
    dispatch_async(movieWritingQueue, ^{
        
        NSError *error;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_finalPath]
                                                     fileType:AVFileTypeMPEG4
                                                        error:&error];
        if (error) {
            NSLog(@"AVAssetWriter error:%@", error);
        }
        
        recordingWillBeStarted = YES;
        
    });
    
    //    //添加定时器
    [self removeRecordTimer];
    [self addRecordTimer];
}
-(void)addRecordTimer{
//    dispatch_queue_t queue = dispatch_queue_create("com.LDJ.AVEngineDemo.timerQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        NSLog(@"dispathNow,%@",[NSDate date]);
        //[self zoomChangeValue:1+(100-_duration)/5.00];
        if (_duration--<=0) {
            [self stopVideoRecoding];
            return;
        }
    });
    dispatch_resume(timer);
    self.timer = timer;

}
-(void)removeRecordTimer{
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }

}

//结束录制
- (void)stopVideoRecoding
{
    [self removeRecordTimer];
    dispatch_async(movieWritingQueue, ^{
        
        _isRecording = NO;
        readyToRecordVideo = NO;
        readyToRecordAudio = NO;
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            self.assetWriterVideoInput = nil;
            self.assetWriterAudioInput = nil;
            self.assetWriter = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self saveVideo2PhotoAlbum:_finalPath];
                if ([self.delegate respondsToSelector:@selector(didFinishRecordingWithError:)]) {
                    [self.delegate didFinishRecordingWithError:nil];
                }
            });
            
        }];
    });
    
}
- (void)saveVideo2PhotoAlbum:(NSString *)videoPath{
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"temp.mov"];
    NSURL *tempURL =[NSURL fileURLWithPath:tempPath];
    if ([[NSFileManager defaultManager]fileExistsAtPath:tempPath]) {
        NSError *error;
        [[NSFileManager defaultManager]removeItemAtPath:tempPath error:&error];
        if (error) {
            NSLog(@"%@",error);
        }
    }
    
    [self convertSpeed:_scale WithVideo:[NSURL fileURLWithPath:videoPath] outputUrl:tempURL completed:^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            
            ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
            [assetLibrary writeVideoAtPathToSavedPhotosAlbum:tempURL completionBlock:^(NSURL *assetURL, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"转换后的视频文件写入到相册，路径：%@",assetURL);
                    if ([self.delegate respondsToSelector:@selector(didFinishSaveToPhotoAlbumWithError:)]) {
                        [self.delegate didFinishSaveToPhotoAlbumWithError:error];
                    }
                    
                });
            }];
        });
    }];
  
    
}
- (void)convertSpeed:(double)scale WithVideo:(NSURL *)videoURL outputUrl:(NSURL *)outputURL  completed:(void(^)())completed {
    // 获取视频
    if (!videoURL) {
        NSLog(@"要转换的视频URL不能为空");
        return;
    }else{
        
        AVURLAsset *videoAsset = nil;
        if(videoURL) {
            videoAsset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
        }
        
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale));
        
        
        
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
        
        CMTimeRange scaleRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale));
        CMTimeRangeShow(scaleRange);
        
        CMTime toDuration_before = CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale);
        CMTime toDuration_after = CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale);

        [compositionVideoTrack scaleTimeRange:scaleRange toDuration:toDuration_after];
        
        AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
        assetExport.outputFileType = AVFileTypeMPEG4;
        assetExport.outputURL = outputURL;
        //        assetExport.timeRange  =CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value*4, videoAsset.duration.timescale));
        assetExport.shouldOptimizeForNetworkUse = YES;
        [assetExport exportAsynchronouslyWithCompletionHandler:^{
            switch ([assetExport status]) {
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[assetExport error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                default:
                    break;
            }
            completed();
        }];
    }
}

- (void)    captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection
{
    
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
                    videoHasRecorded = YES;
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
                    if (videoHasRecorded == YES) {
                        [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                    }
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
- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    NSData *currentChannelLayoutData = nil;
    
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
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
            
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else {
        
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

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
    
    NSLog(@"videoCompressionSetting:%@", videoCompressionSettings);
    
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                    outputSettings:videoCompressionSettings];
        
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;

        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
        else {
            
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }
    else {
        
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(NSString *)mediaType
{
    switch (self.assetWriter.status) {
        case AVAssetWriterStatusUnknown:{
            if ([self.assetWriter startWriting]) {
                
                CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self.assetWriter startSessionAtSourceTime:timestamp];
            }
            else {
                
                NSLog(@"AVAssetWriter startWriting error:%@", self.assetWriter.error);
            }
            break;
        }
        case AVAssetWriterStatusWriting:{
            if (mediaType == AVMediaTypeVideo) {
                
                if (self.assetWriterVideoInput.readyForMoreMediaData) {
                
                    if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                        
                        NSLog(@"isRecording:%d, willBeStarted:%d", self.isRecording, recordingWillBeStarted);
                        NSLog(@"AVAssetWriterInput video appendSapleBuffer error:%@", self.assetWriter.error);
                    }
                }
            }
            else if (mediaType == AVMediaTypeAudio) {
                
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                    
                    if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                        
                        NSLog(@"AVAssetWriterInput audio appendSapleBuffer error:%@", self.assetWriter.error);
                    }
                }
            }
            break;
        }
        case AVAssetWriterStatusCompleted:NSLog(@"AssetWriter.status--AVAssetWriterStatusCompleted");
        case AVAssetWriterStatusFailed:NSLog(@"AssetWriter.status--AVAssetWriterStatusFailed");
        case AVAssetWriterStatusCancelled:NSLog(@"AssetWriter.status--AVAssetWriterStatusCancelled");
        default:
            break;
    }

}

@end
