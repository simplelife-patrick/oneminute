
//
//  DLYMiniVlogTemplate.m
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMiniVlogTemplate.h"
#import "DLYMiniVlogVirtualPart.h"
#import <RNDecryptor.h>

@interface DLYMiniVlogPart()
{
    
}

@end

@implementation DLYMiniVlogTemplate

-(instancetype)initWithTemplateId:(NSString *)templateId{
    
    if (self = [super init]) {
        
        if (templateId) {
            
            NSData *encryptedData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:templateId ofType:nil]];
            
            NSError *error;
            NSData *decryptedData = [RNDecryptor decryptData:encryptedData withPassword:@"dlyvlog2016" error:&error];
            
            if (error!=nil) {
                DLYLog(@"文件解密错误 :%@",error);
            }
            
            if (decryptedData) {
                NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:decryptedData options:NSJSONReadingMutableContainers error:nil];
                self.templateId = [dic objectForKey:@"id"];
                self.templateTitle = [dic objectForKey:@"title"];
                self.version = [dic objectForKey:@"version"];
                self.parts = [dic objectForKey:@"info"];
                self.BGM = [dic objectForKey:@"BGM"];
                self.subTitle1 = [dic objectForKey:@"subTitle1"];
                self.dateWaterMark = [dic objectForKey:@"dateWaterMark"];
                self.videoHeaderType = [[dic objectForKey:@"header"] integerValue];
                self.videoTailerType = [[dic objectForKey:@"tailer"] integerValue];
                self.templateDescription = [dic objectForKey:@"templateDescription"];
                self.filterName = [dic objectForKey:@"filter"];
                self.sampleVideoName = [kTEMPLATE_SAMPLE_API stringByAppendingFormat:@"%@",[dic objectForKey:@"sampleVideoName"]];
                if ([dic valueForKey:@"border"]) {
                    self.previewBorderName = [NSString stringWithFormat:@"%@_preview.png",[dic valueForKey:@"border"]];
                    self.renderBorderName = [NSString stringWithFormat:@"%@_render.png",[dic valueForKey:@"border"]];
                    if ([[NSBundle mainBundle]pathForResource:self.renderBorderName ofType:nil]) {
                        
                    }else{
                        self.renderBorderName = [NSString stringWithFormat:@"%@_render.gif",[dic valueForKey:@"border"]];
                        if (![[NSBundle mainBundle]pathForResource:self.renderBorderName ofType:nil]) {
                            self.renderBorderName = [NSString stringWithFormat:@"%@_render.png",[dic valueForKey:@"border"]];
                        }
                    }
                }
            }else{
                DLYLog(@"模板脚本文件解析出错");
            }
        }else{
            templateId = kDEFAULT_TEMPLATE_NAME;
            DLYLog(@"模板名称为空");
        }
    }
    _virtualParts = self.virtualParts;
    return self;
}

-(NSArray<DLYMiniVlogPart *> *)parts{
    
    NSMutableArray *mArray = [NSMutableArray array];
    
    for (int i = 0; i < _parts.count; i++) {
        NSDictionary *dic = (NSDictionary *)_parts[i];
        
        DLYMiniVlogPart *part = [[DLYMiniVlogPart alloc]init];
        part.partNum = [[dic objectForKey:@"partNum"] integerValue];
        part.partType = [[dic objectForKey:@"partType"] integerValue];
        part.ifCombin = [[dic objectForKey:@"ifCombin"] integerValue];
        part.dubStartTime = [dic objectForKey:@"dubStartTime"];
        part.dubStopTime = [dic objectForKey:@"dubStopTime"];
        part.recordType = [[dic objectForKey:@"recordType"] integerValue];
        part.soundType = [[dic objectForKey:@"soundType"] integerValue];
        part.BGMVolume = [[dic objectForKey:@"BGMVolume"] floatValue];
        part.transitionType = [[dic objectForKey:@"transitionType"] integerValue];
        part.shootGuide = [dic objectForKey:@"shootGuide"];
        part.partPath = [dic objectForKey:@"partPath"];
        [mArray addObject:part];
    }
    return [mArray copy];
}
-(NSMutableArray<DLYMiniVlogVirtualPart *> *)virtualParts{
    if (!_virtualParts) {
        _virtualParts = [NSMutableArray array];
        int combinVirtualPartNum = -1;
        for (DLYMiniVlogPart *part in self.parts) {
            if (part.partType == DLYMiniVlogPartTypeComputer) {
                continue;
            }

            if(part.ifCombin){//需要拍摄并且需要合并的
                DLYMiniVlogVirtualPart *virtualPart;
                NSMutableArray *partsArray;
                if (combinVirtualPartNum>=0) {
                    virtualPart = _virtualParts[combinVirtualPartNum];
                    partsArray = virtualPart.partsInfo;
                }else{
                    virtualPart = [[DLYMiniVlogVirtualPart alloc] init];
                    partsArray = [NSMutableArray array];
                    virtualPart.partsInfo = partsArray;
                    [_virtualParts addObject:virtualPart];
                }
                [partsArray addObject:part];
                combinVirtualPartNum =(int)_virtualParts.count-1;
            }else{
                DLYMiniVlogVirtualPart *virtualPart = [[DLYMiniVlogVirtualPart alloc] init];
                NSMutableArray *partsArray = [NSMutableArray array];
                [partsArray addObject:part];
                virtualPart.partsInfo = partsArray;
                [_virtualParts addObject:virtualPart];

            }
        }
        for (DLYMiniVlogVirtualPart *virtualPart in _virtualParts) {
            double totalDutation = 0;
            BOOL isFirst = YES;
            for (DLYMiniVlogPart *part in virtualPart.partsInfo) {
                if(isFirst){
                    isFirst = NO;

                    virtualPart.shootGuide =part.shootGuide;
                    virtualPart.recordType = part.recordType;
                    virtualPart.soundType = part.soundType;
                    virtualPart.partNum = part.partNum;
                }else{
                    if(virtualPart.recordType!=part.recordType){
                        DLYLog(@"需要合成的模板视频类型不一致！");
                    }
                }
                
                double _start_ = [self getTimeWithString:part.dubStartTime];
                double _stop_ = [self getTimeWithString:part.dubStopTime];
                totalDutation += (_stop_ -_start_);



            };
            virtualPart.dubStartTime = @"00:00:00";
            virtualPart.dubStopTime = [NSString stringWithFormat:@"00:%00.f:00",(totalDutation / 1000)];
            
        }
        if (combinVirtualPartNum>=0) {
            DLYMiniVlogVirtualPart *virtualPart = _virtualParts[combinVirtualPartNum];
            virtualPart.partNum = combinVirtualPartNum;
         
        }

    }
    
    return _virtualParts;
}
-(NSArray<DLYMiniVlogVirtualPart *> *)combinDurationWithParts:(NSArray<DLYMiniVlogPart *> *)parts{
    
    NSMutableArray *mArray = [NSMutableArray array];

    double totalDutation = 0;
    
    DLYMiniVlogVirtualPart *virtualPart = [[DLYMiniVlogVirtualPart alloc] init];
    
    for (DLYMiniVlogPart *part in parts) {
        double _start_ = [self getTimeWithString:part.dubStartTime];
        double _stop_ = [self getTimeWithString:part.dubStopTime];
        totalDutation += (_stop_ -_start_);
    };
    virtualPart.dubStartTime = @"00:00:00";
    virtualPart.dubStopTime = [NSString stringWithFormat:@"00:%00.f:00",(totalDutation / 1000)];
    
    [mArray addObject:virtualPart];
    
    return [mArray copy];
}
- (double)getTimeWithString:(NSString *)timeString
{
    NSArray *stringArr = [timeString componentsSeparatedByString:@":"];
    NSString *timeStr_M = stringArr[0];
    NSString *timeStr_S = stringArr[1];
    NSString *timeStr_MS = stringArr[2];
    
    double timeNum_M = [timeStr_M doubleValue] * 60 * 1000;
    double timeNum_S = [timeStr_S doubleValue] * 1000;
    double timeNum_MS = [timeStr_MS doubleValue] * 10;
    double timeNum = timeNum_M + timeNum_S + timeNum_MS;
    return timeNum;
}
@end
