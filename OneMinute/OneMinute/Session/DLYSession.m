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

- (BOOL) draftExitAtFile{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *homeDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentPath = [homeDir objectAtIndex:0];
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"Data"];
    NSString *draftPath = [dataPath stringByAppendingPathComponent:@"Draft"];
    
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

+ (DLYMiniVlogTemplate *)loadTemplateWithTemplateId:(NSString *)templateId{
    
    DLYMiniVlogTemplate *template = [[DLYMiniVlogTemplate alloc] initWithTemplateName:templateId];
    
    return template;
}

- (void)resetSession{
    
    if ([self draftExitAtFile]) {
        DLYResource *resouece = [[DLYResource alloc] init];
        NSArray *draftArray = [resouece loadBDraftParts];
    }else{
        _currentTemplate = [[DLYMiniVlogTemplate alloc] initWithTemplateName:@"001"];
    }
}

@end
