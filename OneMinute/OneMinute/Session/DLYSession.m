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

-(DLYMiniVlogTemplate *)currentTemplate{
    if (!_currentTemplate) {
        
        DLYMiniVlogTemplate *template = nil;
        _resource = [[DLYResource alloc] init];
        
        NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_ID];

        if (savedCurrentTemplateName) {//有保存模板
            
            BOOL isExitDraft = [self isExistDraftAtFile];
            if (isExitDraft) {//有草稿
                
                double saveVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_VERSION] doubleValue];
                template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:kDEFAULTTEMPLATENAME];
                double version = [template.version doubleValue];
                
                if (saveVersion != version) {//模板已升级
                    DLYLog(@"模板已升级!");
                    //清空草稿
                    BOOL isSuccess = [_resource removeCurrentAllPartFromDocument];
                    DLYLog(@"%@",isSuccess ? @"成功删除旧模板的草稿片段!":@"删除旧模板的草稿片段失败!");
                    template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];

                }else{//存在草稿.模板未升级
                    template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
                    
                    NSArray *arr = [self.resource loadDraftPartsFromDocument];
                    
                    NSMutableArray *draftArr = [NSMutableArray array];
                    for (NSURL *url in arr) {
                        NSString *partPath = url.path;
                        NSString *newPath = [partPath stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
                        NSArray *arr = [newPath componentsSeparatedByString:@"part"];
                        NSString *partNum = arr.lastObject;
                        [draftArr addObject:partNum];
                    }
                    template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
                    NSArray *parts = template.parts;
                    
                    //设置片段预处理状态
                    for (int i = 0; i < [parts count]; i++) {
                        
                        DLYMiniVlogPart *part = parts[i];
                        if (i == 0) {
                            part.prepareRecord = @"1";
                        }else {
                            part.prepareRecord = @"0";
                        }
                        part.recordStatus = @"0";
                        part.duration = [self getDurationwithStartTime:part.starTime andStopTime:part.stopTime];
                        part.partTime = [self getDurationwithStartTime:part.dubStartTime andStopTime:part.dubStopTime];
                        
                    }
                    //设置片段完成状态
                    for (NSString *str in draftArr) {
                        NSInteger num = [str integerValue];
                        DLYMiniVlogPart *part = parts[num];
                        part.recordStatus = @"1";
                    }
                    
                    for (DLYMiniVlogPart *part1 in parts) {
                        part1.prepareRecord = @"0";
                    }
                    
                    for(int i = 0; i < [parts count]; i++)
                    {
                        DLYMiniVlogPart *part2 = parts[i];
                        if([part2.recordStatus isEqualToString:@"0"])
                        {
                            part2.prepareRecord = @"1";
                            break;
                        }
                    }
                }
            }else{//无草稿
                template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
            }
        }else{//无保存模板
            DLYLog(@"当前保存的模板名称键值为空,加载默认模板");
            template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:kDEFAULTTEMPLATENAME];
        }
        DLYLog(@"当前加载的模板是 :%@",template.templateId);
        return template;
    }else{
        return _currentTemplate;
    }
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
