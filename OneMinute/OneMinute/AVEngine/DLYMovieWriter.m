
//
//  DLYMovieWriter.m
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMovieWriter.h"
#import "DLYContextManager.h"
#import "DLYFunctions.h"
#import "DLYPhotoFilters.h"

@interface DLYMovieWriter ()

@property (strong, nonatomic) AVAssetWriter                        *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput                   *assetWriterVideoInput;
@property (strong, nonatomic) AVAssetWriterInput                   *assetWriterAudioInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferAdaptor;

@property (strong, nonatomic) dispatch_queue_t                     dispatchQueue;
@property (nonatomic, strong) dispatch_queue_t                     movieWritingQueue;
@property (nonatomic, strong) dispatch_semaphore_t                 semaphore;
@property (nonatomic) BOOL                                         firstSample;

@property (weak, nonatomic) CIContext                              *ciContext;
@property (nonatomic) CGColorSpaceRef                              colorSpace;
@property (strong, nonatomic) CIFilter                             *activeFilter;
@property (strong, nonatomic) CIFilter                             *transformFilter;

@property (strong, nonatomic) NSDictionary                         *videoSettings;
@property (strong, nonatomic) NSDictionary                         *audioSettings;

@end

@implementation DLYMovieWriter

- (id)initWithVideoSettings:(NSDictionary *)videoSettings
              audioSettings:(NSDictionary *)audioSettings
              dispatchQueue:(dispatch_queue_t)dispatchQueue {
    
    self = [super init];
    if (self) {
        _videoSettings = videoSettings;
        _audioSettings = audioSettings;
        _dispatchQueue = dispatchQueue;
        _movieWritingQueue = dispatch_queue_create("_movieWritingQueue", NULL);
        _ciContext = [DLYContextManager sharedInstance].ciContext;
        _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _activeFilter = [[DLYPhotoFilters sharedInstance] defaultFilter];
        _transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        CGAffineTransform t = CGAffineTransformMakeRotation(M_PI);
//        [_transformFilter setValue:[NSValue valueWithCGAffineTransform:t] forKey:@"inputTransform"];
        _firstSample = YES;
        _semaphore = dispatch_semaphore_create(1);
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(filterChanged:)
                   name:DLYFilterSelectionChangedNotification
                 object:nil];
    }
    return self;
}
-(void)setOutputUrl:(NSURL *)outputUrl{
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputUrl.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputUrl.path error:nil];
    }
    _outputUrl = outputUrl;
}
- (void)dealloc {
    CGColorSpaceRelease(_colorSpace);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)filterChanged:(NSNotification *)notification {
    self.activeFilter = [notification.object copy];
}

- (void)startWritingWith:(UIDeviceOrientation)orientation AndCameraPosition:(DLYAVEngineCapturePositionType)position{
    dispatch_async(self.movieWritingQueue, ^{
        
        NSError *error = nil;
        
        NSString *fileType = AVFileTypeMPEG4;
        self.assetWriter = [AVAssetWriter assetWriterWithURL:self.outputUrl fileType:fileType error:&error];
        
        if (!self.assetWriter || error) {
            NSString *formatString = @"Could not create AVAssetWriter: %@";
            DLYLog(@"%@", [NSString stringWithFormat:formatString, error]);
            return;
        }
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                       outputSettings:self.videoSettings];
        
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
//        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//        self.assetWriterVideoInput.transform = DLYTransformForDeviceOrientation(orientation);
        CGAffineTransform transform;
        if (position == DLYAVEngineCapturePositionTypeBack) {
            transform =DLYTransformForDeviceOrientation(orientation);
            if (orientation ==UIDeviceOrientationLandscapeRight) {
                transform.tx = [self.videoSettings[AVVideoWidthKey] floatValue];
                transform.ty = [self.videoSettings [AVVideoHeightKey] floatValue];
            }else{
                transform.tx = 0;
                transform.ty = 0;
            }
        }else{
            if (orientation ==UIDeviceOrientationLandscapeRight) {
                transform = CGAffineTransformIdentity;
                transform.tx = 0;
                transform.ty = 0;

            }else{
                transform = CGAffineTransformMakeRotation(M_PI);
                transform.tx = [self.videoSettings[AVVideoWidthKey] floatValue];
                transform.ty = [self.videoSettings [AVVideoHeightKey] floatValue];
            }
        }
        [_transformFilter setValue:[NSValue valueWithCGAffineTransform:transform] forKey:@"inputTransform"];

 

        NSDictionary *attributes = @{
                                     (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                     (id)kCVPixelBufferWidthKey : self.videoSettings[AVVideoWidthKey],
                                     (id)kCVPixelBufferHeightKey : self.videoSettings[AVVideoHeightKey],
                                     (id)kCVPixelFormatOpenGLESCompatibility : (id)kCFBooleanTrue
                                     };
        
        self.assetWriterInputPixelBufferAdaptor =
        [[AVAssetWriterInputPixelBufferAdaptor alloc]
         initWithAssetWriterInput:self.assetWriterVideoInput
         sourcePixelBufferAttributes:attributes];
        
        
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            [self.assetWriter addInput:self.assetWriterVideoInput];
        } else {
            DLYLog(@"Unable to add video input.");
            return;
        }
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                       outputSettings:self.audioSettings];
        
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        } else {
            DLYLog(@"Unable to add audio input.");
        }
        
        self.isWriting = YES;
        self.firstSample = YES;
    });
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    if (!self.isWriting) {
        return;
    }
    
    CMFormatDescriptionRef formatDesc =
    CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        
        CMTime timestamp =
        CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (self.firstSample) {
            if ([self.assetWriter startWriting]) {
                [self.assetWriter startSessionAtSourceTime:timestamp];
            } else {
                DLYLog(@"Failed to start writing.");
            }
            self.firstSample = NO;
        }
        
        CVPixelBufferRef outputRenderBuffer = NULL;
        
        CVPixelBufferPoolRef pixelBufferPool =
        self.assetWriterInputPixelBufferAdaptor.pixelBufferPool;
        
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(NULL,
                                                          pixelBufferPool,
                                                          &outputRenderBuffer);
        if (err) {
            DLYLog(@"Unable to obtain a pixel buffer from the pool.");
            return;
        }
        
        CVPixelBufferRef imageBuffer =
        CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer
                                                       options:nil];
        
        [self.activeFilter setValue:sourceImage forKey:kCIInputImageKey];
        [self.transformFilter setValue:self.activeFilter.outputImage forKey:kCIInputImageKey];
        CIImage *filteredImage = self.transformFilter.outputImage;
    
        if (!filteredImage) {
            filteredImage = sourceImage;
        }
        [self.ciContext render:filteredImage
               toCVPixelBuffer:outputRenderBuffer
                        bounds:filteredImage.extent
                    colorSpace:self.colorSpace];
        
        
        if (self.assetWriterVideoInput.readyForMoreMediaData) {
            if (![self.assetWriterInputPixelBufferAdaptor
                  appendPixelBuffer:outputRenderBuffer
                  withPresentationTime:timestamp]) {
                DLYLog(@"Error appending pixel buffer.");
            }
        }
        
        CVPixelBufferRelease(outputRenderBuffer);
        
    }
    else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                DLYLog(@"Error appending audio sample buffer.");
            }
        }
    }
    
}
-(void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!self.isWriting) {
        return;
    }
    if (!self.firstSample) {
        if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                DLYLog(@"Error appending audio sample buffer.");
            }
        }
    }
}
-(void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!self.isWriting) {
        return;
    }
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    CMTime timestamp =
    CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if (self.firstSample) {
        if ([self.assetWriter startWriting]) {
            [self.assetWriter startSessionAtSourceTime:timestamp];
        } else {
            DLYLog(@"Failed to start writing.");
        }
        self.firstSample = NO;
    }
    
    CVPixelBufferRef outputRenderBuffer = NULL;
    
    CVPixelBufferPoolRef pixelBufferPool =
    self.assetWriterInputPixelBufferAdaptor.pixelBufferPool;
    
    OSStatus err = CVPixelBufferPoolCreatePixelBuffer(NULL,
                                                      pixelBufferPool,
                                                      &outputRenderBuffer);
    if (err) {
        DLYLog(@"Unable to obtain a pixel buffer from the pool.");
        return;
    }
    
    CVPixelBufferRef imageBuffer =
    CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer
                                                   options:nil];
    
    [self.activeFilter setValue:sourceImage forKey:kCIInputImageKey];
    [self.transformFilter setValue:self.activeFilter.outputImage forKey:kCIInputImageKey];
    CIImage *filteredImage = self.transformFilter.outputImage;
    
    if (!filteredImage) {
        filteredImage = sourceImage;
    }
    [self.ciContext render:filteredImage
           toCVPixelBuffer:outputRenderBuffer
                    bounds:filteredImage.extent
                colorSpace:self.colorSpace];
    
    
    if (self.assetWriterVideoInput.readyForMoreMediaData) {
        if (![self.assetWriterInputPixelBufferAdaptor
              appendPixelBuffer:outputRenderBuffer
              withPresentationTime:timestamp]) {
            DLYLog(@"Error appending pixel buffer.");
        }
    }
    
    CVPixelBufferRelease(outputRenderBuffer);
    dispatch_semaphore_signal(self.semaphore);
}
- (void)stopWriting {
    
    self.isWriting = NO;
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self.movieWritingQueue, ^{
        if (self.assetWriter.status == 0) {
            
        }else{
            [self.assetWriter finishWritingWithCompletionHandler:^{
                
                if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSURL *fileURL = [self.assetWriter outputURL];
                        [self.delegate didWriteMovieAtURL:fileURL];
                    });
                } else {
                    DLYLog(@"Failed to write movie: %@", self.assetWriter.error);
                }
                self.assetWriter = nil;
                self.assetWriterVideoInput = nil;
                self.assetWriterAudioInput = nil;
            }];
        }
        
        dispatch_semaphore_signal(self.semaphore);

    });
}

@end
