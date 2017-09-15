//
//  ZHMovieObject.h
//  Vlog
//
//  Created by chenzonghai on 16/08/2017.
//  Copyright © 2017 Arex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale//swscale.h>

@interface DLYMovieObject : NSObject

/* 解码后的UIImage */
@property (nonatomic, strong, readonly) UIImage *currentImage;

/* 视频的frame高度 */
@property (nonatomic, assign, readonly) int sourceWidth, sourceHeight;

/* 输出图像大小。默认设置为源大小。 */
@property (nonatomic,assign) int outputWidth, outputHeight;

/* 视频的长度，秒为单位 */
@property (nonatomic, assign, readonly) double duration;

/* 视频的当前秒数 */
@property (nonatomic, assign, readonly) double currentTime;

/* 视频的帧率 */
@property (nonatomic, assign, readonly) double fps;

/* 视频路径。 */
- (instancetype)initWithVideo:(NSString *)moviePath;
/* 切换资源 */
- (void)replaceTheResources:(NSString *)moviePath;
/* 重拨 */
- (void)redialPaly;
/* 从视频流中读取下一帧。返回假，如果没有帧读取（视频）。 */
- (BOOL)stepFrame;

/* 寻求最近的关键帧在指定的时间 */
- (void)seekTime:(double)seconds;

@end
