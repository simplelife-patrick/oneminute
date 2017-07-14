//
//  DLYSession.h
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"
#import "DLYMiniVlogTemplate.h"

@interface DLYSession : DLYModule

/**
  当前模板
 */
@property (nonatomic, strong) DLYMiniVlogTemplate                *currentTemplate;

/**
 判断是否存在未完成的草稿

 @return 返回结果
 */
- (BOOL) draftExitAtFile;

/**
 传入模板编号返回模板数据

 @param templateId 模板编号
 @return 加载好的模板数据
 */

+ (DLYMiniVlogTemplate *)loadTemplateWithTemplateId:(NSString *)templateId;
/**
 重置sesion
 */
- (void)resetSession;

@end
