

//
//  DLYMobileDevice.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMobileDevice.h"

@implementation DLYMobileDevice
//创建单例
+ (DLYMobileDevice *) sharedDevice
{
    static  DLYMobileDevice *sharedDevice = nil ;
    static  dispatch_once_t onceToken;
    dispatch_once (& onceToken, ^ {
        //初始化自己
        sharedDevice = [[self alloc] init];
    });
    return  sharedDevice;
}
//手机uuid
-(NSString *)getIphoneIdentifier{
    return [[UIDevice currentDevice] identifierForVendor].UUIDString;
}
//手机别名
-(NSString *)getIphoneName{
    return [[UIDevice currentDevice] name];
}
//手机系统名称
-(NSString *)getIphoneSystemName{
    return [[UIDevice currentDevice] systemName];
}
//手机系统版本
-(NSString *)getIphoneSystemVersion{
    return [[UIDevice currentDevice] systemVersion];
}
//获取手机型号
-(NSString *)getIphoneModel{
    return [[UIDevice currentDevice] model];
}
//获取手机型号
- (DLYPhoneDeviceType )iPhoneType {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    if (strlen(systemInfo.machine) == 0) {
        return PhoneDeviceTypeNone;
    }
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([platform isEqualToString:@"iPhone5,1"]) return PhoneDeviceTypeIphone_5;
    
    if ([platform isEqualToString:@"iPhone5,2"]) return PhoneDeviceTypeIphone_5;
    
    if ([platform isEqualToString:@"iPhone5,3"]) return PhoneDeviceTypeIphone_5c;
    
    if ([platform isEqualToString:@"iPhone5,4"]) return PhoneDeviceTypeIphone_5c;
    
    if ([platform isEqualToString:@"iPhone6,1"]) return PhoneDeviceTypeIphone_5s;
    
    if ([platform isEqualToString:@"iPhone6,2"]) return PhoneDeviceTypeIphone_5s;
    
    if ([platform isEqualToString:@"iPhone7,1"]) return PhoneDeviceTypeIphone_6_Plus;
    
    if ([platform isEqualToString:@"iPhone7,2"]) return PhoneDeviceTypeIphone_6;
    
    if ([platform isEqualToString:@"iPhone8,1"]) return PhoneDeviceTypeIphone_6s;
    
    if ([platform isEqualToString:@"iPhone8,2"]) return PhoneDeviceTypeIphone_6s_Plus;
    
    if ([platform isEqualToString:@"iPhone8,4"]) return PhoneDeviceTypeIphone_SE;
    
    if ([platform isEqualToString:@"iPhone9,1"]) return PhoneDeviceTypeIphone_7;
    
    if ([platform isEqualToString:@"iPhone9,2"]) return PhoneDeviceTypeIphone_7_Plus;
    
    return PhoneDeviceTypeNone;
}
-(NSString *)iPhoneModel{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    if (strlen(systemInfo.machine) == 0) {
        return nil;
    }
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone_5";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone_5";
    
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone_5c";
    
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone_5c";
    
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone_5s";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone_5s";
    
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone_6Plus";
    
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone_6";
    
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone_6s";
    
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone_6sPlus";
    
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone_SE";
    
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone_7";
    
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone_7Plus";
    
    return platform;
}
@end
