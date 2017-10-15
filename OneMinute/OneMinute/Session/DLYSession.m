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
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY]) {
        
        NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:savedCurrentTemplateName];
        
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateId:kDEFAULTTEMPLATENAME];
    }
    return _currentTemplate;
}
- (void)saveCurrentTemplateWithId:(NSString *)currentTemplateId{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentTemplateId forKey:kCURRENTTEMPLATEKEY];
    
    if ([defaults synchronize]) {

    }else{
        DLYLog(@"⚠️⚠️⚠️Current template saved failure!");
    };
}
- (NSArray *) loadAllTemplateFile {
    
    //获取系统版本
    double systemVersion = [[UIDevice currentDevice] systemVersion].doubleValue;
    NSString *jsonFile = nil;
    
    if (systemVersion <= 1.0) {
        jsonFile = [[NSBundle mainBundle] pathForResource:@"TemplateList_v1.plist" ofType:nil];
    }else {
        jsonFile = [[NSBundle mainBundle] pathForResource:@"TemplateList_v1.plist" ofType:nil];
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:jsonFile];
    
    NSMutableArray *templateListArrray = [NSMutableArray array];
    for (NSString *templateId in dic) {
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
