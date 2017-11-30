//
//  DLYSession.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYSession.h"
#import "DLYMiniVlogTemplate.h"

@interface DLYSession ()

@property (nonatomic, strong) NSString                *savedCurrentTemplateName;

@end

@implementation DLYSession


-(DLYMiniVlogTemplate *)currentTemplate{
    
    DLYMiniVlogTemplate *template = nil;
    
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_ID];
    if (savedCurrentTemplateName) {
        template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
    }else{
        template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:kDEFAULT_TEMPLATE_NAME];
    }
    return template;
}

- (void) detectionTemplateForLaunchComplated:(ComplatedBlock)complated
{
    NSString *_templateName = nil;
    NSString *_version;
    _resource = [[DLYResource alloc] init];
    
    _savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_ID];
    NSString *saveVersion = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENT_TEMPLATE_VERSION];
    //1. 是否有保存的模板
    if (_savedCurrentTemplateName) {//有保存的模板
        
        if([self isExistTemplate]){//保存的模板存在
            //获取模板保存的版本号
            double oldVersion = [saveVersion doubleValue];
            //获取模板当前最新的版本号
            DLYMiniVlogTemplate *template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:_savedCurrentTemplateName];
            double newVersion = [template.version doubleValue];
            
            //3. 此模板保存的版本号和最新的版本号是否一致
            if (oldVersion == newVersion) {//版本号一致
                DLYLog(@"模板版本校验OK!");
            }else{//版本号不一样,模板已升级
                DLYLog(@"模板版本已升级");
                //删除草稿
                [self.resource removeCurrentAllPartFromDocument];
                complated(YES);
                DLYLog(@"保存的模板版本已升级,此模板旧版本拍摄的草稿片段被清空");
            }
            _templateName = _savedCurrentTemplateName;
            _version = template.version;
            
        }else{//保存的模板不存在
            
            //删除草稿
            [self.resource removeCurrentAllPartFromDocument];
            complated(YES);
            //加载默认模板
            _templateName = kDEFAULT_TEMPLATE_NAME;
        }
    }else{//无保存的模板
        DLYLog(@"当前保存的模板名称键值为空,重置当前模板为默认模板");
        _templateName = _savedCurrentTemplateName;
    }
    [self saveCurrentTemplateWithId:_templateName version:_version];
}
- (BOOL) isExistTemplate
{
    BOOL isExist = NO;
    NSArray *templateArray = [self loadAllTemplateFile];
    for (NSString *templateId in templateArray) {
        //2. 保存的模板是否存在
        if([templateId isEqualToString:_savedCurrentTemplateName]){
            DLYLog(@"保存的模板存在");
            return YES;
        }else{
            isExist = NO;
            DLYLog(@"保存的模板不存在");
        }
    }
    return isExist;
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

- (BOOL) isExistDraftAtFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    
    if ([fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        if([fileManager fileExistsAtPath:draftPath]){
            NSString *virtualPath = [draftPath stringByAppendingPathComponent:kVirtualFolder];
            
            if ([fileManager fileExistsAtPath:virtualPath]) {
                
                NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:virtualPath error:nil];
                DLYLog(@"当前模板已经有 %lu 个完成的片段",[draftArray count]);
                if ([draftArray count]) {
                    return YES;
                }else{
                    return NO;
                }
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
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:@"Default.dly"];
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
