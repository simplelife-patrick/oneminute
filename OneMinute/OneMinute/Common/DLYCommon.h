//
//  DLYCommon.h
//  OneMinute
//
//  Created by chenzonghai on 08/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DLYLogModule.h"
#import <CocoaSecurity.h>
#import <CoreGraphics/CoreGraphics.h>

#import "DLYAlertView.h"
#import "UIView+Extension.h"
#import "UIView+Utility.h"
#import<CocoaLumberjack/CocoaLumberjack.h>
#import "NSObject+JSONCategories.h"
#import "UIImage+iconfont.h"
#import "UIButton+LargerHitArea.h"
#import <UMengAnalytics/UMMobClick/MobClick.h>
#import <Photos/Photos.h>
#import "UIColor+Hex.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <AFNetworking/AFNetworking.h>

#ifdef DEBUG
//#import "FLEXManager.h"
static const int ddLogLevel = DDLogLevelVerbose;

#else
static const int ddLogLevel = DDLogLevelError;
//#define DLog(...);
#endif

@interface DLYCommon : NSObject

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
#define kSampleFolder @"Sample"
#define kProductFolder @"Product"
#define kDraftFolder @"Draft"
#define kBGMFolder @"BGM"
#define kVideoHeaderFolder @"VideoHeader"
#define kVideoTailerFolder @"VideoTailer"
#define kSoundEffectFolder @"SoundEffect"

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
@end
