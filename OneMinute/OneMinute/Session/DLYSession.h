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
 保存当前拍摄模板

 @param currentTemplateName 当前模板名称
 */
- (void) saveCurrentTemplateWithName:(NSString *)currentTemplateName;

/**
 获取当前模板

 @return 返回模板
 */
- (DLYMiniVlogTemplate *)getCurrentTemplate;

/**
 判断是否存在草稿

 @return 返回结果
 */
- (BOOL) isExistDraftAtFile;

/**
 传入模板编号返回模板数据

 @param templateName 模板名称
 @return 加载好的模板数据
 */

- (DLYMiniVlogTemplate *)loadTemplateWithTemplateName:(NSString *)templateName;
/**
 重置sesion
 */
- (void)resetSession;

@end
