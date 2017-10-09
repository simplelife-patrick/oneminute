//
//  DLYMobileDevice.h
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sys/utsname.h"

@interface DLYMobileDevice : NSObject

typedef NS_ENUM(NSInteger , DLYPhoneDeviceType) {
    PhoneDeviceTypeNone,
    PhoneDeviceTypeIphone_5,
    PhoneDeviceTypeIphone_5c,
    PhoneDeviceTypeIphone_5s,
    PhoneDeviceTypeIphone_6_Plus,
    PhoneDeviceTypeIphone_6,
    PhoneDeviceTypeIphone_6s,
    PhoneDeviceTypeIphone_6s_Plus,
    PhoneDeviceTypeIphone_SE,
    PhoneDeviceTypeIphone_7,
    PhoneDeviceTypeIphone_7_Plus,
    PhoneDeviceTypeIPad_1G,
    PhoneDeviceTypeIPad_2,
    PhoneDeviceTypeIPadMini_1G,
    PhoneDeviceTypeIPad_3,
    PhoneDeviceTypeIPad_4,
    PhoneDeviceTypeIPad_Air,
    PhoneDeviceTypeIPadMini_2G,
};
//创建单例
+ (DLYMobileDevice *) sharedDevice;
//获取手机型号
- (DLYPhoneDeviceType )iPhoneType ;
//手机uuid
-(NSString *)getIphoneIdentifier;
//手机别名
-(NSString *)getIphoneName;
//手机系统名称
-(NSString *)getIphoneSystemName;
//手机系统版本
-(NSString *)getIphoneSystemVersion;
//获取手机型号
-(NSString *)getIphoneModel;
//返回手机型号已字符串格式返回
-(NSString *)iPhoneModel;

@end
