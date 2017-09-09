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
- (BOOL) isExitdraftAtFile{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [kPathDocument stringByAppendingPathComponent:kDataFolder];
    
    if ([fileManager fileExistsAtPath:dataPath]) {
        
        NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
        
        if ([fileManager fileExistsAtPath:draftPath]) {
        
            NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
            DLYLog(@"The current folder have %lu files",(unsigned long)draftArray.count);
            if ([draftArray count]) {
                //Draft box is not empty
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
    
    if ([self isExitdraftAtFile]) {
        
        DLYMiniVlogTemplate *currentTemplate = [self currentTemplate];
        
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:currentTemplate.templateName];
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:@"Universal001.json"];
    }
}

@end
