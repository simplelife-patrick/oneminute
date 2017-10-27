//
//  DLYSession.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYSession.h"
#import "DLYMiniVlogTemplate.h"

@implementation DLYSession

- (NSString *) detectionForLaunch
{
    DLYMiniVlogTemplate *template = nil;
    _resource = [[DLYResource alloc] init];
    
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_ID];
    //1. 是否有保存的模板
    if (savedCurrentTemplateName) {//有保存的模板
        
        NSArray *templateArray = [self loadAllTemplateFile];
        for (NSString *templateId in templateArray) {
            //2. 保存的模板是否存在
            if([templateId isEqualToString:savedCurrentTemplateName]){//保存的模板存在
                DLYLog(@"保存的模板存在");
                
                //获取模板保存的版本号
                double saveVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_VERSION] doubleValue];
                //获取模板当前最新的版本号
                template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
                double version = [template.version doubleValue];
                
                //3. 此模板保存的版本号和最新的版本号是否一致
                if (saveVersion == version) {//版本号一致
                    DLYLog(@"模板版本校验OK!");
                }else{//版本号不一样,模板已升级
                    DLYLog(@"模板版本已升级");
                    //删除草稿
                    [self.resource removeCurrentAllPartFromDocument];
                }
                return savedCurrentTemplateName;
            }else{
                //保存的模板不存在
                DLYLog(@"保存的模板不存在");
                //删除草稿
                [self.resource removeCurrentAllPartFromDocument];
                //加载默认模板
                return kDEFAULT_TEMPLATE_NAME;
            }
        }
    }else{//无保存的模板
        DLYLog(@"当前保存的模板名称键值为空,重置当前模板为默认模板");
        return kDEFAULT_TEMPLATE_NAME;
    }
    return nil;
}
- (void) saveCurrentTemplateWithId:(NSString *)currentTemplateId version:(NSString *)version{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentTemplateId forKey:kCURRENT_TEMPLATE_ID];
    [defaults setObject:version forKey:kCURRENT_TEMPLATE_VERSION];
    
    if ([defaults synchronize]) {
        DLYLog(@"当前模板保存成功!");
    }else{
        DLYLog(@"保存当前模板失败!");
    };
}
- (NSArray *) loadAllTemplateFile {
    
    //获取应用当前版本号
    NSDictionary*infoDic = [[NSBundle mainBundle] infoDictionary];
    double localVersion = [[infoDic objectForKey:@"CFBundleShortVersionString"] doubleValue];
    
    NSString *jsonFile = nil;
    
    if (localVersion <= 1.0) {
        jsonFile = [[NSBundle mainBundle] pathForResource:@"templateList_v1.plist" ofType:nil];
    }else {
        jsonFile = [[NSBundle mainBundle] pathForResource:@"templateList_v1.plist" ofType:nil];
    }
    
    NSArray *arrry = [NSArray arrayWithContentsOfFile:jsonFile];
    
    NSMutableArray *templateListArrray = [NSMutableArray array];
    
    for (NSInteger i = 0; i < [arrry count]; i++) {
        
        NSString *templateId = arrry[i];
        [templateListArrray addObject:templateId];
    }
    return templateListArrray;
}
- (DLYMiniVlogTemplate *) getCurrentTemplate {
    
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_ID];
    DLYMiniVlogTemplate *currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
    return currentTemplate;
}
- (BOOL) isExistDraftAtFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    
    if ([fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        
        if ([fileManager fileExistsAtPath:draftPath]) {
        
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            DLYLog(@"当前模板已经有 %lu 个完成的片段",[draftArray count]);
            if ([draftArray count]) {
                return YES;
            }
        }
    }
    return NO;
}

- (DLYMiniVlogTemplate *)loadTemplateWithTemplateName:(NSString *)templateName{
    
    DLYMiniVlogTemplate *template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:templateName];
    
    return template;
}

- (void)resetSession{
    
    if ([self isExistDraftAtFile]) {
        
        DLYMiniVlogTemplate *currentTemplate = [self currentTemplate];
        
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:currentTemplate.templateId];
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:@"Primary.dly"];
    }
}
- (NSString *)getDurationwithStartTime:(NSString *)startTime andStopTime:(NSString *)stopTime {
    
    int startDuration = 0;
    int stopDuation = 0;
    NSArray *startArr = [startTime componentsSeparatedByString:@":"];
    for (int i = 0; i < 3; i ++) {
        NSString *timeStr = startArr[i];
        int time = [timeStr intValue];
        if (i == 0) {
            startDuration = startDuration + time * 60 * 1000;
        }if (i == 1) {
            startDuration = startDuration + time * 1000;
        }else {
            startDuration = startDuration + time;
        }
    }
    
    NSArray *stopArr = [stopTime componentsSeparatedByString:@":"];
    for (int i = 0; i < 3; i ++) {
        NSString *timeStr = stopArr[i];
        int time = [timeStr intValue];
        if (i == 0) {
            stopDuation = stopDuation + time * 60 * 1000;
        }if (i == 1) {
            stopDuation = stopDuation + time * 1000;
        }else {
            stopDuation = stopDuation + time;
        }
    }
    
    float duration = (stopDuation - startDuration) * 0.001;
    NSString *duraStr = [NSString stringWithFormat:@"%.3f", duration];
    return duraStr;
}

@end
