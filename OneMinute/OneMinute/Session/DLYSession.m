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

#define kDEFAULTTEMPLATENAME  @"Universal001.json"
#define kCURRENTTEMPLATEKEY  @"CURRENTTEMPLATEKEY"

@implementation DLYSession

-(DLYMiniVlogTemplate *)currentTemplate{
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY]) {
        
        NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:savedCurrentTemplateName];
        
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:kDEFAULTTEMPLATENAME];
    }
    return _currentTemplate;
}
- (void)saveCurrentTemplateWithName:(NSString *)currentTemplateName{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentTemplateName forKey:kCURRENTTEMPLATEKEY];
    
    if ([defaults synchronize]) {

    }else{
        DLYLog(@"⚠️⚠️⚠️Current template saved failure!");
    };
}

- (DLYMiniVlogTemplate *)getCurrentTemplate{
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
    DLYMiniVlogTemplate *currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:savedCurrentTemplateName];
    return currentTemplate;

}
- (BOOL) isExitDraftAtFile{
    
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
    
    DLYMiniVlogTemplate *template = [[DLYMiniVlogTemplate alloc] initWithTemplateName:templateName];
    
    return template;
}

- (void)resetSession{
    
    if ([self isExitDraftAtFile]) {
        
        DLYMiniVlogTemplate *currentTemplate = [self currentTemplate];
        
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:currentTemplate.templateName];
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:@"Universal001.json"];
    }
}

@end
