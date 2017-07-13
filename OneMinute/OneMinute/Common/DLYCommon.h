//
//  DLYCommon.h
//  OneMinute
//
//  Created by chenzonghai on 08/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DLYCommon : NSObject

//全局尺寸定义
#define SCREEN_RECT     [[UIScreen mainScreen] bounds]
#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

//沙盒文件目录文件夹
#define kPathDocument [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define DataFolder @"Data"
#define TemplateFolder @"Template"
#define ResourceFolder @"Resource"
#define SampleFolder @"Sample"
#define ProductFolder @"Product"
#define DraftFolder @"Draft"
#define BGMFolder @"BGM"
#define VideoHeaderFolder @"VideoHeader"
#define VideoTailerFolder @"VideoTailer"
#define SoundEffectFolder @"SoundEffect"

@end
