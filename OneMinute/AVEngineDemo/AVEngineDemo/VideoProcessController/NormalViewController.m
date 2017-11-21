//
//  NormalViewController.m
//  AVEngineDemo
//
//  Created by LDJ on 2017/11/9.
//  Copyright © 2017年 LDJ. All rights reserved.
//

#import "NormalViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVManager.h"
@interface NormalViewController ()<AVManagerDelegate>

@property (nonatomic, weak) UIView *container;//播放器容器

@property (nonatomic, weak) UIView *previewView;//预览视图
@property (nonatomic, weak) UIView *containerView;//录制视频容器
@property (nonatomic, weak) UIButton *recordButton;//录制按钮
@property (nonatomic, weak) UILabel *recordTimeLabel;//录制视频时长标签


@property (nonatomic, strong)AVManager *manager;

@end

@implementation NormalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createControl];
    _manager = [[AVManager alloc]initWithPreviewView:_previewView];
    _manager.delegate = self;

}

- (void)createControl
{
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat btnH = 60.f;
    CGFloat marginY = 0.f;
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    
    //内容视图
    CGFloat containerViewH = h - 64 - btnH - marginY * 3;
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 64 + marginY, w, containerViewH)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.borderWidth = 1.f;
    containerView.layer.borderColor = [[UIColor grayColor] CGColor];
    [self.view addSubview:containerView];
    _containerView = containerView;

    //录制时间
    UILabel *recordTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 17, 150, 40)];
    recordTimeLabel.text = @"00:00";
    recordTimeLabel.textColor = [UIColor whiteColor];
    recordTimeLabel.font = [UIFont boldSystemFontOfSize:20.f];
    [containerView addSubview:recordTimeLabel];
    _recordTimeLabel = recordTimeLabel;
    
    //播放器容器
    UIView *container = [[UIView alloc] initWithFrame:containerView.frame];

    [self.view addSubview:container];
    _container = container;
    
    //预览控制面板
    UIView *previewView = [[UIView alloc] initWithFrame:containerView.frame];
    [self.view addSubview:previewView];
    _previewView = previewView;
    
    UIButton *recordButton = [[UIButton alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(containerView.frame), w, btnH)];

    recordButton.backgroundColor = [UIColor orangeColor];
    [recordButton addTarget:self action:@selector(startRecordVideo:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton setTitle:@"录制一个十秒的常速视频" forState:UIControlStateNormal];
    [self.view addSubview:recordButton];
    _recordButton = recordButton;

}

- (void)startRecordVideo:(UIButton *)btn
{
    //更新界面
    _recordTimeLabel.text = @"00:00";
    [btn setTitle:@"录制中请稍后..." forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    btn.enabled = NO;

    [_manager startRecordVideoWithDuration:100 AndScale:1];

}
-(void)didFinishRecordingWithError:(NSError *)error{
    if (error) {
        NSLog(@"保存至相册失败%@",error);
        [_recordButton setTitle:@"录制视频失败" forState:UIControlStateNormal];
    }
    [_recordButton setTitle:@"录制视频成功" forState:UIControlStateNormal];
}
-(void)didFinishSaveToPhotoAlbumWithError:(NSError *)error{
    if (error) {
        NSLog(@"保存至相册失败%@",error);
        [_recordButton setTitle:@"保存至相册失败" forState:UIControlStateNormal];
    }
    [_recordButton setTitle:@"保存至相册成功" forState:UIControlStateNormal];
}


//视频路径
- (NSString *)getPath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", dateStr]];

    return path;
}

- (NSString *)strWithTime:(double)time interval:(CGFloat)interval
{
    int minute = (time * interval) / 60;
    int second = (int)(time * interval) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minute, second];
}

//完成录制
- (void)finishBtnOnClick
{
 

}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
