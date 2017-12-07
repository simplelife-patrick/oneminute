//
//  DLYMovieWriter.h
//  OneMinute
//
//  Created by chenzonghai on 24/11/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, DLYAVEngineCapturePositionType) {
    DLYAVEngineCapturePositionTypeBack = 0,
    DLYAVEngineCapturePositionTypeFront
};

@protocol DLYMovieWriterDelegate<NSObject>

- (void)didWriteMovieAtURL:(NSURL *)outputURL;

@end

@interface DLYMovieWriter : NSObject

@property (nonatomic) BOOL isWriting;
@property (weak, nonatomic) id<DLYMovieWriterDelegate>       delegate;
@property (nonatomic, strong) NSURL                          *outputUrl;


- (void)startWritingWith:(UIDeviceOrientation)orientation AndCameraPosition:(DLYAVEngineCapturePositionType)position;
- (void)stopWriting;
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (id)initWithVideoSettings:(NSDictionary *)videoSettings
              audioSettings:(NSDictionary *)audioSettings
              dispatchQueue:(dispatch_queue_t)dispatchQueue;

@end
