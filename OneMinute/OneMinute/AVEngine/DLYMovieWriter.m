
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
@property (nonatomic) BOOL                                         firstSample;

@property (weak, nonatomic) CIContext                              *ciContext;
@property (nonatomic) CGColorSpaceRef                              colorSpace;
@property (strong, nonatomic) CIFilter                             *activeFilter;

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
        
        _ciContext = [DLYContextManager sharedInstance].ciContext;
        _colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _activeFilter = [DLYPhotoFilters defaultFilter];
        _firstSample = YES;
        
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

- (void)startWriting {
    dispatch_async(self.dispatchQueue, ^{
        
        NSError *error = nil;
        
        NSString *fileType = AVFileTypeMPEG4;
        self.assetWriter = [AVAssetWriter assetWriterWithURL:self.outputUrl fileType:fileType error:&error];
        
        if (!self.assetWriter || error) {
            NSString *formatString = @"Could not create AVAssetWriter: %@";
            NSLog(@"%@", [NSString stringWithFormat:formatString, error]);
            return;
        }
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                       outputSettings:self.videoSettings];
        
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        self.assetWriterVideoInput.transform = DLYTransformForDeviceOrientation(orientation);
        
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
            NSLog(@"Unable to add video input.");
            return;
        }
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                       outputSettings:self.audioSettings];
        
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        } else {
            NSLog(@"Unable to add audio input.");
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
                NSLog(@"Failed to start writing.");
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
            NSLog(@"Unable to obtain a pixel buffer from the pool.");
            return;
        }
        
        CVPixelBufferRef imageBuffer =
        CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer
                                                       options:nil];
        
        [self.activeFilter setValue:sourceImage forKey:kCIInputImageKey];
        
        CIImage *filteredImage = self.activeFilter.outputImage;
        
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
                NSLog(@"Error appending pixel buffer.");
            }
        }
        
        CVPixelBufferRelease(outputRenderBuffer);
        
    }
    else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Error appending audio sample buffer.");
            }
        }
    }
    
}

- (void)stopWriting {
    
    self.isWriting = NO;
    
    dispatch_async(self.dispatchQueue, ^{
        
        [self.assetWriter finishWritingWithCompletionHandler:^{
            
            if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSURL *fileURL = [self.assetWriter outputURL];
                    [self.delegate didWriteMovieAtURL:fileURL];
                });
            } else {
                NSLog(@"Failed to write movie: %@", self.assetWriter.error);
            }
        }];
    });
}

@end
