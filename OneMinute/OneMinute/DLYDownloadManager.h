//
//  DLYDownloadManager.h
//  MyDownLoadFIile
//
//  Created by 陈立勇 on 2017/8/11.
//  Copyright © 2017年 陈立勇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DLYDownloader.h"

@interface DLYDownloadManager : NSObject

+(instancetype)shredManager;


/**
 *  是否存在已经完成的文件
 */

- (BOOL)isExistLocalVideo:(NSString *) videoName andVideoURLString:(NSString *)url;

/**
 *  断点下载
 *
 *  @param urlString        下载的链接
 *  @param destinationPath  下载的文件的保存路径
 *  @param  process         下载过程中回调的代码块，会多次调用
 *  @param  completion      下载完成回调的代码块
 *  @param  failure         下载失败的回调代码块
 */
-(void)downloadWithUrlString:(NSString *)urlString
                      toPath:(NSString *)destinationPath
                     process:(ProcessHandle)process
                  completion:(CompletionHandle)completion
                     failure:(FailureHandle)failure;

/**
 *  暂停下载
 *
 *  @param url 下载的链接
 */
-(void)cancelDownloadTask:(NSString *)url;
/**
 *  暂停所有下载
 */
-(void)cancelAllTasks;
/**
 *  彻底移除下载任务
 *
 *  @param url  下载链接
 *  @param path 文件路径
 */
-(void)removeForUrl:(NSString *)url file:(NSString *)path;
/**
 *  获取上一次的下载进度
 *
 *  @param url 下载链接
 *
 *  @return 下载进度
 */
-(float)lastProgress:(NSString *)url;
/**
 *  获取文件已下载的大小和总大小,格式为:已经下载的大小/文件总大小,如：12.00M/100.00M。
 *
 *  @param url 下载链接
 *
 *  @return 有文件大小及总大小组成的字符串
 */
-(NSString *)filesSize:(NSString *)url;


@end
