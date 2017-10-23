//
//  DLYSession.m
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYSession.h"
#import "DLYMiniVlogTemplate.h"
#import "DLYResource.h"

@implementation DLYSession

-(DLYMiniVlogTemplate *)currentTemplate{
    if (!_currentTemplate) {
        
        DLYMiniVlogTemplate *template = nil;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY]) {
            
            NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
            DLYLog(@"当前保存到模板名称 :%@",savedCurrentTemplateName);
            template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
            
        }else{
            DLYLog(@"当前保存的模板名称键值为空,加载默认模板");
            template = [[DLYMiniVlogTemplate alloc] initWithTemplateId:kDEFAULTTEMPLATENAME];
        }
        DLYLog(@"当前加载的模板是 :%@",template.templateId);
        
        return template;
    }else{
        return _currentTemplate;
    }
}
- (void)saveCurrentTemplateWithId:(NSString *)currentTemplateId{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentTemplateId forKey:kCURRENTTEMPLATEKEY];
    
    if ([defaults synchronize]) {

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
        jsonFile = [[NSBundle mainBundle] pathForResource:@"TemplateList_v1.plist" ofType:nil];
    }else {
        jsonFile = [[NSBundle mainBundle] pathForResource:@"TemplateList_v1.plist" ofType:nil];
    }
    
    NSArray *arrry = [NSArray arrayWithContentsOfFile:jsonFile];
    
    NSMutableArray *templateListArrray = [NSMutableArray array];
    
    for (NSInteger i = 0; i < [arrry count]; i++) {
        
        NSString *templateId = arrry[i];
        [templateListArrray addObject:templateId];
    }
    return templateListArrray;
}
- (DLYMiniVlogTemplate *)getCurrentTemplate{
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
    DLYMiniVlogTemplate *currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
    return currentTemplate;
}
- (BOOL) isExistDraftAtFile{
    
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
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:@"Universal001.json"];
    }
}

@end
