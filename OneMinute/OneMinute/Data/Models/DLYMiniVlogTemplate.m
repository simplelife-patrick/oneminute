
//
//  DLYMiniVlogTemplate.m
//  OneMinute
//
//  Created by chenzonghai on 10/07/2017.
//  Copyright © 2017 动旅游. All rights reserved.
//

#import "DLYMiniVlogTemplate.h"

@implementation DLYMiniVlogTemplate

-(instancetype)initWithTemplateName:(NSString *)templateName{
    
    if (self = [super init]) {
        
        [NSBundle mainBundle] ;
        NSString *path = [[NSBundle mainBundle] pathForResource:templateName ofType:nil];
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        self.templateName = [dic objectForKey:@"id"];
        self.templateTitle = [dic objectForKey:@"title"];
        self.templateType = [[dic objectForKey:@"type"] integerValue];
        self.parts = [dic objectForKey:@"info"];
        self.BGM = [dic objectForKey:@"BGM"];
        self.videoHeader = [dic objectForKey:@"header"];
        self.videoTailer = [dic objectForKey:@"tailer"];
        self.templateDescription = [dic objectForKey:@"templateDescription"];
        self.sampleVideoName = [dic objectForKey:@"sampleVideoName"];
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
        part.dubStarTime = [dic objectForKey:@"dubStartTime"];
        part.dubStopTime = [dic objectForKey:@"dubStopTime"];
        part.recordType = [[dic objectForKey:@"recordType"] integerValue];
        part.soundType = [[dic objectForKey:@"soundType"] integerValue];
        part.transitionType = [[dic objectForKey:@"transitionType"] integerValue];
        [mArray addObject:part];
    }
    return [mArray copy];
}

@end
