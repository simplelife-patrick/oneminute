
//
//  DLYPublicMacros.h
//  OneMinute
//
//  Created by chenzonghai on 20/09/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#ifndef DLYPublicMacros_h
#define DLYPublicMacros_h


//全局尺寸定义
#define SCREEN_RECT     [[UIScreen mainScreen] bounds]
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height
#define SCALE_WIDTH SCREEN_WIDTH/667
#define SCALE_HEIGHT SCREEN_HEIGHT/375

//沙盒文件目录文件夹
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kDataFolder @"Data"
#define kTemplateFolder @"Template"
#define kResourceFolder @"Resource"
#define kProductFolder @"Product"
#define kDraftFolder @"Draft"
#define kTempFolder @"Temp"
#define kBGMFolder @"BGM"

#define kVideoHeaderFolder @"VideoHeader"
#define kVideoTailerFolder @"VideoTailer"
#define kSoundEffectFolder @"SoundEffect"

//默认模板
#define kDEFAULT_TEMPLATE_NAME  @"Default.dly"
//当前模板名称
#define kCURRENT_TEMPLATE_ID  @"CURRENT_TEMPLATE_ID"
//当前模板的模板
#define kCURRENT_TEMPLATE_VERSION  @"CURRENT_TEMPLATE_VERSION"
//样片基地址
#define kTEMPLATE_SAMPLE_API  @"http://dly.oss-cn-shanghai.aliyuncs.com/"

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

#define DLog(format, ...) DDLogError((@"[文件名:%s]" "[函数名:%s]" "[行号:%d]" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);


#endif /* DLYPublicMacros_h */
