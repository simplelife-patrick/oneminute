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

#define kDEFAULTTEMPLATENAME  @"Universal_001.json"
#define kCURRENTTEMPLATEKEY  @"CURRENTTEMPLATEKEY"

@implementation DLYSession

-(DLYMiniVlogTemplate *)currentTemplate{
    if (!_currentTemplate) {
        
        if ([self isExitdraftAtFile] && [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY]) {
            
            NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
            _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:savedCurrentTemplateName];
            
        }else{
            
            _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:kDEFAULTTEMPLATENAME];
        }
        [[NSUserDefaults standardUserDefaults] setObject:kDEFAULTTEMPLATENAME forKey:kCURRENTTEMPLATEKEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return _currentTemplate;
}
- (void)saveCurrentTemplateWithName:(NSString *)currentTemplateName{
    
    NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] init];
    [defaults setObject:currentTemplateName forKey:kCURRENTTEMPLATEKEY];
}
- (DLYMiniVlogTemplate *)getCurrentTemplate{
    NSString *savedCurrentTemplateName = [[NSUserDefaults standardUserDefaults] objectForKey:kCURRENTTEMPLATEKEY];
    DLYMiniVlogTemplate *currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:savedCurrentTemplateName];
    return currentTemplate;

}
- (BOOL) isExitdraftAtFile{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentPath = [homeDir objectAtIndex:0];
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:kDataFolder];
    NSString *draftPath = [dataPath stringByAppendingPathComponent:kDraftFolder];
    
    if ([fileManager fileExistsAtPath:dataPath] && [fileManager fileExistsAtPath:draftPath]) {
        
        NSArray *draftArray = [fileManager contentsOfDirectoryAtPath:draftPath error:nil];
        DLYLog(@"The current folder have %lu files",(unsigned long)draftArray.count);
        if ([draftArray count]) {
            //Draft box is not empty
            return YES;
        }
    }
    return NO;
}

+ (DLYMiniVlogTemplate *)loadTemplateWithTemplateName:(NSString *)templateName{
    
    DLYMiniVlogTemplate *template = [[DLYMiniVlogTemplate alloc] initWithTemplateName:templateName];
    
    return template;
}

- (void)resetSession{
    
    if ([self isExitdraftAtFile]) {
        
        DLYResource *resouece = [[DLYResource alloc] init];
        NSArray *draftArray = [resouece loadBDraftParts];
        DLYMiniVlogTemplate *currentTemplate = [self currentTemplate];
        
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:currentTemplate.templateName];
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:@"Universal_001.json"];
    }
}

@end
