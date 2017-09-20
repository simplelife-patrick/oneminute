
//
//  DLYPublicMacros.h
//  OneMinute
//
//  Created by chenzonghai on 20/09/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#ifndef DLYPublicMacros_h
#define DLYPublicMacros_h

#define APPTEST [[NSBundle mainBundle].infoDictionary[@"APPTEST"] boolValue]
//全局尺寸定义
#define SCREEN_RECT     [[UIScreen mainScreen] bounds]
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

//沙盒文件目录文件夹
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kDataFolder @"Data"
#define kTemplateFolder @"Template"
#define kResourceFolder @"Resource"
#define kProductFolder @"Product"
#define kDraftFolder @"Draft"
#define kBGMFolder @"BGM"
#define kVideoHeaderFolder @"VideoHeader"
#define kVideoTailerFolder @"VideoTailer"
#define kSoundEffectFolder @"SoundEffect"

#define kPartNum @"kPartNum"
#define kMoviePath @"kMoviePath"
#define kMovieTime @"kMovieTime"
#define kMovieSpeed @"kMovieSpeed"
#define kMovieIndex @"kMovieIndex"
#define kMovieSpeed_Normal @"kMovieSpeed_Normal"
#define kMovieSpeed_Fast @"kMovieSpeed_Fast"
#define kMovieSpeed_Slow @"kMovieSpeed_Slow"
// 合成视频本地存储路径
#define kVideoPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject

//默认模板
#define kDEFAULTTEMPLATENAME  @"Universal001.json"
//全局当前模板
#define kCURRENTTEMPLATEKEY  @"CURRENTTEMPLATEKEY"


#define DLog(format, ...) DDLogError((@"[文件名:%s]" "[函数名:%s]" "[行号:%d]" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);

#define SCALE_WIDTH SCREEN_WIDTH/667
#define SCALE_HEIGHT SCREEN_HEIGHT/375


//图片字体库
#define ICONFONT @"iconfont"

//color
#define RGB(r,g,b)                  [UIColor colorWithRed:r / 255.f green:g / 255.f blue:b / 255.f alpha:1.f]
#define RGBA(r,g,b,a)               [UIColor colorWithRed:r / 255.f green:g / 255.f blue:b / 255.f alpha:a]

#define RGB_HEX(hex)                RGBA((float)((hex & 0xFF0000) >> 16),(float)((hex & 0xFF00) >> 8),(float)(hex & 0xFF),1.f)
#define RGBA_HEX(hex,a)             RGBA((float)((hex & 0xFF0000) >> 16),(float)((hex & 0xFF00) >> 8),(float)(hex & 0xFF),a)

// Font
#define FONT_SYSTEM(s)        [UIFont systemFontOfSize:s]
#define FONT_BOLD(s)          [UIFont boldSystemFontOfSize:s]

// GCD
#define GCD_GLOBAL(block)           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define GCD_MAIN(block)             dispatch_async(dispatch_get_main_queue(), block)

#endif /* DLYPublicMacros_h */
