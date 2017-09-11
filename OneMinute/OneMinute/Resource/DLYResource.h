//
//  DLYResource.h
//  OneMinute
//
//  Created by chenzonghai on 12/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYModule.h"

typedef  NS_ENUM(NSInteger, DLYResourceType){
    DLYResourceTypeVideoHeader = 0,
    DLYResourceTypeVideoTailer,
    DLYResourceTypeBGM,
    DLYResourceTypeSoundEffect,
    DLYResourceTypeSampleVideo
};

@interface DLYResource : DLYModule

@property (nonatomic, strong) NSFileManager                *fileManager;
@property (nonatomic, strong) NSString                     *resourceFolderPath;
@property (nonatomic, strong) NSString                     *resourcePath;
@property (nonatomic, strong) NSString                     *currentProductPath;


/**
 获取模板样片视频

 @param sampleName 样片名称
 */
- (NSURL *) getTemplateSampleWithName:(NSString *)sampleName;
/**
 加载资源文件

 @param resourceType 资源类型
 @param fileName 文件名称
 @return 返回在沙盒中的地址
 */
- (NSURL *) loadResourceWithType:(DLYResourceType )resourceType fileName:(NSString *)fileName;

/**
 加载草稿片段从Cache中
 
 @return 返回草稿全部片段
 */
- (NSArray *)loadDraftPartsFromeCache;

/**
 加载草稿片段从Document

 @return 返回全部草稿片段
 */
- (NSArray *) loadDraftPartsFromeDocument;
/**
 保存草稿片段到沙盒中

 @param partNum 片段序号
 @return 返回片段保存地址
 */

- (NSURL *) saveDraftPartWithPartNum:(NSInteger)partNum;

/**
 保存成片视频到沙盒中

 @return 返回保存地址
 */
- (NSURL *) saveProductToSandbox;

/**
 保存文件到沙盒文件夹
 
 @param resourcePath 文件夹路径
 @param suffixName 文件后缀名
 @return 返回保存后的URL
 */
- (NSURL *) saveToSandboxWithPath:(NSString *)resourcePath suffixType:(NSString *)suffixName;

/**
 通用文件保存API

 @param sandboxFolderType 沙盒文件夹类型 (Document/Libray/tmp)
 @param subfolderName 子文件夹名称
 @param suffixName 文件后缀名
 @return 返回保存URL
 */
- (NSURL *) saveToSandboxFolderType:(NSSearchPathDirectory)sandboxFolderType subfolderName:(NSString *)subfolderName suffixType:(NSString *)suffixName;

/**
 按片段序号删除Cache中的草稿片段

 @param partNum 草稿片段序号
 */
- (void) removePartWithPartNumFormCache:(NSInteger)partNum;

/**
 按片段序号删除Document中的草稿片段

 @param partNum 草稿片段序号
 */
- (void) removePartWithPartNumFromDocument:(NSInteger)partNum;

/**
 删除Cache中全部草稿片段
 */
- (void) removeCurrentAllPartFromCache;

/**
  删除Document中全部草稿片段
 */
- (void) removeCurrentAllPartFromDocument;
/**
 获取单个片段的播放地址

 @param partNum 片段序号
 */
- (NSURL *) getPartUrlWithPartNum:(NSInteger)partNum;

/**
 获取成片视频的播放地址
 */
- (NSURL *) getProductWithProductName:(NSString *)productName;










- (NSString *) getSaveDraftPartWithPartNum:(NSInteger)partNum;

@end
