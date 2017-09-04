//
//  DLYExportViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYExportViewController.h"
#import "DLYAnnularProgress.h"
#import "ViewController.h"
#import "DLYRecordViewController.h"

@interface DLYExportViewController (){
    
    double _shootTime;
}

@property (nonatomic, strong) UIView *syntheticView;


@property (nonatomic, strong) DLYAnnularProgress * progressView;
@property (nonatomic, strong) UILabel *remindLabel;
@property (nonatomic, strong) UIView *centerView;

@property (nonatomic, strong) NSTimer *shootTimer;//定时器
@property (nonatomic, strong) UIButton *successButton;
@property (nonatomic, strong) UIButton *completeButton;

@end

@implementation DLYExportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createMainView];
}

- (void)createMainView {
    
    //背景图片
    UIImageView * videoImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    videoImage.image = self.backImage;
    [self.view addSubview:videoImage];
    
    self.syntheticView = [[UIView alloc]initWithFrame:self.view.frame];
    self.syntheticView.backgroundColor = RGBA(0, 0, 0, 0.5);
    [self.view addSubview:self.syntheticView];
    
    self.centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 113 * SCALE_HEIGHT, 68, 68)];
    self.centerView.centerX = self.view.centerX;
    [self.syntheticView addSubview:self.centerView];
    
    //圆形进度条
    self.progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, self.centerView.width, self.centerView.height)];
    self.progressView.progress = 0.01;
    self.progressView.circleRadius = 28;
    self.progressView.fillColor = [UIColor clearColor];
    self.progressView.lineColor = [UIColor whiteColor];
    [self.centerView addSubview:self.progressView];
    
    //完成图片
    self.successButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.centerView.width, self.centerView.height)];
    self.successButton.layer.borderWidth = 3.0;
    self.successButton.layer.borderColor = RGB(255, 0, 0).CGColor;
    self.successButton.layer.cornerRadius = self.successButton.width / 2.0;
    self.successButton.clipsToBounds = YES;
    self.successButton.contentMode = UIViewContentModeScaleAspectFill;
    [self.successButton setImage:[UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:30 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
    self.successButton.hidden = YES;
    [self.centerView addSubview:self.successButton];
    
    //提示label
    self.remindLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.centerView.bottom + 16, 120, 44)];
    self.remindLabel.centerX = self.view.centerX;
    self.remindLabel.textAlignment = NSTextAlignmentCenter;
    self.remindLabel.text = @"正在合成...";
    self.remindLabel.font = FONT_SYSTEM(16);
    self.remindLabel.textColor = [UIColor whiteColor];
    self.remindLabel.numberOfLines = 0;
    [self.syntheticView addSubview:self.remindLabel];
    
    //完成按钮
    self.completeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.remindLabel.bottom + 32, 120, 40)];
    self.completeButton.centerX = self.view.centerX;
    self.completeButton.layer.cornerRadius = 25;
    self.completeButton.clipsToBounds = YES;
    self.completeButton.layer.borderWidth = 1;
    self.completeButton.layer.borderColor = RGB(255, 255, 255).CGColor;
    [self.completeButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.completeButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.completeButton.titleLabel.font = FONT_SYSTEM(16);
    self.completeButton.hidden = YES;
    [self.completeButton addTarget:self action:@selector(onClickComplete) forControlEvents:UIControlEventTouchUpInside];
    [self.syntheticView addSubview:self.completeButton];
    
    _shootTime = 0.0;
    _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(exportAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_shootTimer forMode:NSRunLoopCommonModes];
    
}

- (void)onClickComplete {

    NSArray *arr = self.navigationController.viewControllers;
    DLYRecordViewController *recoedVC = arr[0];
    recoedVC.isExport = YES;
    [self.navigationController popToViewController:recoedVC animated:YES];
    
}

- (void)exportAction {
    _shootTime += 0.01;
    
    [_progressView drawProgress: _shootTime / 3.0 withColor:RGB(255, 0, 0)];
    if(_shootTime >= 3.0)
    {
        [_shootTimer invalidate];
        [self finishExportVideo];
    }
}
//完成之后（带延时操作）
- (void)finishExportVideo {
    
    self.progressView.hidden = YES;
    self.successButton.hidden = NO;
    self.remindLabel.text = @"影片已合成\n保存在本地相册";
    self.completeButton.hidden = NO;
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        
//        NSArray *arr = self.navigationController.viewControllers;
//        DLYRecordViewController *recoedVC = arr[0];
//        recoedVC.isExport = YES;
//        [self.navigationController popToViewController:recoedVC animated:YES];
//    });
    
}

#pragma mark - 页面将要显示
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ExportView"];
    if (self.beforeState == 1) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }else {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ExportView"];
}
#pragma mark - 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//            NSLog(@"导出页面左转");
        }];
    }
}
- (void)deviceChangeAndHomeOnTheRight {
    
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
//            NSLog(@"导出页面右转");
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
