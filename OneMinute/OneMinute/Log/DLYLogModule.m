//
//  DLYLogModule.m
//  OneMinute
//
//  Created by 邓柯 on 2017/6/7.
//  Copyright © 2017年 动旅游. All rights reserved.
//


#import "DLYLogModule.h"
#import "ZipArchive.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDLegacyMacros.h>


#define LOG_FLAG_VIDEO_INFO     (1 << 6)                // 0...0100 0000

#define LOG_LEVEL_VIDEO_OFF     0
#define LOG_LEVEL_VIDEO_INFO    (LOG_FLAG_VIDEO_INFO)   // 0...0100 0000
#define LOG_LEVEL_VIDEO_DEF     (LOG_LEVEL_VIDEO_INFO)

#define _DLYLogInfo(frmt, ...)  LOG_OBJC_MAYBE(LOG_ASYNC_INFO, LOG_LEVEL_VIDEO_DEF, LOG_FLAG_VIDEO_INFO, 0, frmt, ##__VA_ARGS__)


#ifdef PrereleaseEnviroment
static int64_t const DTVideoMaximumNumberOfLogFiles = 7;            // 个
static int64_t const DTVideoMaximumFileSize = 1 * 1024 * 1024;      // Byte
//static DTVideoConferenceLogLevel const DTVideoCurrentLogLevel = DTVideoConferenceLogLevel_INFO;
#else
static int64_t const DTVideoMaximumNumberOfLogFiles = 7;            // 个
static int64_t const DTVideoMaximumFileSize = 1 * 1024 * 1024;      // Byte
//static DTVideoConferenceLogLevel const DTVideoCurrentLogLevel = DTVideoConferenceLogLevel_ERROR;
#endif


@interface DLYLogFormatter : NSObject<DDLogFormatter>

@property(nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation DLYLogFormatter

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *dateAndTime = [_dateFormatter stringFromDate:(logMessage->_timestamp)];
    
    return [NSString stringWithFormat:@"%@ %@", dateAndTime, logMessage->_message];
}

@end


@interface DLYLogModule()
{
    DDLogFileManagerDefault *_logFileManager;
    DDFileLogger *_logger;
    NSString *_logDirectory;
}

@end


@implementation DLYLogModule

SINGLETON(DLYLogModule)

-(void) initModule
{
    [super initModule];
}

- (void)instanceInit
{
    [self _setLogConfigure];
}

#pragma mark - Log APIs

- (void)loggerFormat:(NSString *)format, ...
{
    if (format)
    {
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        if (log)
        {
            // TODO: 邓柯
//            _DLYLogInfo(log,nil);
            DDLogInfo(log, nil);
        }
    }
}

- (void)stopLogRecordWithFileName:(void(^)(NSString *base64String))completion
{
    NSString *base_64 = nil;
    NSArray *filesArray = [_logFileManager sortedLogFileNames];
    if (filesArray.count > 0)
    {
        NSString *file_Name = [filesArray firstObject];
        NSString *file_Path = [_logDirectory stringByAppendingFormat:@"/%@",file_Name];
        
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:file_Path];
        if (isExist)
        {
            //写文件
            NSString *log_Name = @"video_temp.log";
            NSString *zip_Name = @"video_temp.zip";
            NSString *zip_Path = [NSTemporaryDirectory() stringByAppendingPathComponent:zip_Name];
            //压缩
            ZipArchive *zipTool = [[ZipArchive alloc] init];
            BOOL zipResult = [zipTool CreateZipFile2:zip_Path];
            [zipTool addFileToZip:file_Path newname:log_Name];
            if (zipResult)
            {
                NSData *zip_data = [NSData dataWithContentsOfFile:zip_Path];
                base_64 = [zip_data base64EncodedStringWithOptions:0];
            }
        }
    }
    
    if (completion)
    {
        completion(base_64);
    }
    
    [_logger rollLogFileWithCompletionBlock:^{
        
    }];
}

#pragma mark - Private APIs

- (void)_setLogConfigure
{
    // sends log to a file into ~/Library/Caches/Logs/log-*
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _logDirectory = [NSString stringWithFormat:@"%@/Logs/", cacheDirectory];
    
    _logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:_logDirectory];
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
//    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:_logFileManager]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = DTVideoMaximumNumberOfLogFiles;
    fileLogger.maximumFileSize = DTVideoMaximumFileSize;
    [DDLog addLogger:fileLogger];
}

@end
