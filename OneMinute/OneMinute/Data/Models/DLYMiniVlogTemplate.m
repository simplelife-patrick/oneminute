
//
//  DLYMiniVlogTemplate.m
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMiniVlogTemplate.h"
#import <RNDecryptor.h>

@implementation DLYMiniVlogTemplate

-(instancetype)initWithTemplateId:(NSString *)templateId{
    
    if (self = [super init]) {
        
        if (templateId) {
            
            NSData *encryptedData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:templateId ofType:nil]];
            
            NSError *error;
            NSData *decryptedData = [RNDecryptor decryptData:encryptedData withPassword:@"dlyvlog2016" error:&error];
            
            if (!error) {
                DLYLog(@"JSON Data Dencrypt Success!");
            }
            
            if (decryptedData) {
                NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:decryptedData options:NSJSONReadingMutableContainers error:nil];
                self.templateId = [dic objectForKey:@"id"];
                self.templateTitle = [dic objectForKey:@"title"];
                self.version = [[dic objectForKey:@"version"] doubleValue];
                self.parts = [dic objectForKey:@"info"];
                self.BGM = [dic objectForKey:@"BGM"];
                self.subTitle1 = [dic objectForKey:@"subTitle1"];
                self.videoHeaderType = [[dic objectForKey:@"header"] integerValue];
                self.videoTailerType = [[dic objectForKey:@"tailer"] integerValue];
                self.templateDescription = [dic objectForKey:@"templateDescription"];
                self.sampleVideoName = [kTEMPLATE_SAMPLE_API stringByAppendingFormat:@"%@",[dic objectForKey:@"sampleVideoName"]];
            }else{
                DLYLog(@"模板脚本文件解析出错");
            }
        }else{
            templateId = kDEFAULTTEMPLATENAME;
            DLYLog(@"模板名称为空");
        }
    }
    return self;
}

-(NSArray<DLYMiniVlogPart *> *)parts{
    
    NSMutableArray *mArray = [NSMutableArray array];
    
    for (int i = 0; i < _parts.count; i++) {
        NSDictionary *dic = (NSDictionary *)_parts[i];
        
        DLYMiniVlogPart *part = [[DLYMiniVlogPart alloc]init];
        part.partNum = [[dic objectForKey:@"partNum"] integerValue];
        part.starTime = [dic objectForKey:@"startTime"];
        part.stopTime = [dic objectForKey:@"stopTime"];
        part.dubStartTime = [dic objectForKey:@"dubStartTime"];
        part.dubStopTime = [dic objectForKey:@"dubStopTime"];
        part.recordType = [[dic objectForKey:@"recordType"] integerValue];
        part.soundType = [[dic objectForKey:@"soundType"] integerValue];
        part.BGMVolume = [[dic objectForKey:@"BGMVolume"] floatValue];
        part.transitionType = [[dic objectForKey:@"transitionType"] integerValue];
        part.shootGuide = [dic objectForKey:@"shootGuide"];
        [mArray addObject:part];
    }
    return [mArray copy];
}
- (NSString*)description{
    return [NSString stringWithFormat:@"<%@: %p> {templateId: %@ ,version: %f ,templateTitle: %@,templateDescription:%@,sampleVideoName: %@ ,parts: %@ ,BGM: %@,subTitle1:%@,videoHeaderType: %@ ,videoTailerType: %ld}",[self class],self,self.templateId,self.version,self.templateTitle,self,self.templateDescription,self.sampleVideoName,self.parts,self.BGM,self.subTitle1,(long)self.videoHeaderType,self.videoTailerType];
}
@end
