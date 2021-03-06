//
//  DLYExportViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYExportViewController.h"
#import "DLYAnnularProgress.h"
#import "DLYRecordViewController.h"
#import "DLYResource.h"
#import <UShareUI/UShareUI.h>
@interface DLYExportViewController ()<YBPopupMenuDelegate>
{
    double _shootTime;
}

@property (nonatomic, strong) UIView *syntheticView;


@property (nonatomic, strong) DLYAnnularProgress * progressView;
@property (nonatomic, strong) UILabel *remindLabel;
@property (nonatomic, strong) UIView *centerView;

@property (nonatomic, strong) NSTimer *shootTimer;//定时器
@property (nonatomic, strong) UIButton *successButton;
@property (nonatomic, strong) UIButton *completeButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIView *backView;

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
    
    self.backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 58, 58)];
    self.backView.centerX = self.centerView.width / 2;
    self.backView.centerY = self.centerView.height / 2;
    self.backView.layer.cornerRadius = 29;
    self.backView.clipsToBounds = YES;
    self.backView.layer.borderWidth = 2.0;
    self.backView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.centerView addSubview:self.backView];
    //圆形进度条
    self.progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, self.centerView.width, self.centerView.height)];
    self.progressView.circleRadius = 28;
    self.progressView.keyPath = @"strokeEnd";
    [self.centerView addSubview:self.progressView];
    self.progressView.animationTime = 3.0;
    
    //完成图片
    self.successButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.centerView.width, self.centerView.height)];
    self.successButton.layer.borderWidth = 3.0;
    self.successButton.layer.borderColor = RGB(255, 0, 0).CGColor;
    self.successButton.layer.cornerRadius = self.successButton.width / 2.0;
    self.successButton.clipsToBounds = YES;
    self.successButton.contentMode = UIViewContentModeScaleAspectFill;
    [self.successButton setImage:[UIImage imageWithIconName:IFSuccessful inFont:ICONFONT size:30 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
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
    self.completeButton.layer.cornerRadius = self.completeButton.bounds.size.height/2;
    self.completeButton.clipsToBounds = YES;
    self.completeButton.layer.borderWidth = 1;
    self.completeButton.layer.borderColor = RGB(255, 255, 255).CGColor;
    [self.completeButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.completeButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.completeButton.titleLabel.font = FONT_SYSTEM(16);
    self.completeButton.hidden = YES;
    [self.completeButton addTarget:self action:@selector(onClickComplete) forControlEvents:UIControlEventTouchUpInside];
    [self.syntheticView addSubview:self.completeButton];
    
    
    //分享按钮
    if (NEW_FUNCTION) {
        self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-30-50, 30, 50, 50)];
        self.shareButton.layer.cornerRadius = self.shareButton.bounds.size.height/2;
        self.shareButton.clipsToBounds = YES;
        self.shareButton.layer.borderWidth = 1;
        self.shareButton.layer.borderColor = RGB(255, 255, 255).CGColor;
        [self.shareButton setTitle:@"分享" forState:UIControlStateNormal];
        [self.shareButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
        self.shareButton.titleLabel.font = FONT_SYSTEM(16);
        self.shareButton.hidden = YES;
        [self.shareButton addTarget:self action:@selector(onClickShare) forControlEvents:UIControlEventTouchUpInside];
        [self.syntheticView addSubview:self.shareButton];
    }

    
    _shootTime = 0.0;
    _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(exportAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_shootTimer forMode:NSRunLoopCommonModes];
    
}

- (void)onClickComplete {
    [DLYUserTrack recordAndEventKey:@"ExportFinish"];
    DLYResource *resource = [[DLYResource alloc] init];
    [resource removeCurrentAllPartFromDocument];
    [resource removeProductFromDocument];
    NSArray *arr = self.navigationController.viewControllers;
    DLYRecordViewController *recoedVC = arr[0];
    recoedVC.isExport = YES;
    [self.navigationController popToViewController:recoedVC animated:YES];
}
-(void)onClickShare{
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        // 根据获取的platformType确定所选平台进行下一步操作
        UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
        
        UMShareVideoObject *shareObject = [UMShareVideoObject shareObjectWithTitle:@"分享标题" descr:@"分享内容描述" thumImage:[UIImage imageNamed:@"flash"]];
        shareObject.videoUrl = @"http://video.sina.com.cn/p/sports/cba/v/2013-10-22/144463050817.html";
        //            shareObject.videoStreamUrl = @"这里设置视频数据流地址（如果有的话，而且也要看所分享的平台支不支持）";
        
        messageObject.shareObject = shareObject;
        
        [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:self completion:^(id data, NSError *error) {
            if (error) {
                NSLog(@"************Share fail with error %@*********",error);
            }else{
                NSLog(@"response data is %@",data);
            }
        }];
        
        
    }];

}
- (void)exportAction {
    _shootTime += 0.01;
    
    if(_shootTime >= 3.0)
    {
        [_shootTimer invalidate];
        [self finishExportVideo];
    }
}

//完成之后（带延时操作）
- (void)finishExportVideo {
    
    self.backView.hidden = YES;
    self.progressView.hidden = YES;
    self.successButton.hidden = NO;
    if (NEW_FUNCTION) {
        self.shareButton.hidden = NO;
    }
    self.remindLabel.text = @"影片已合成\n保存在本地相册";
    self.completeButton.hidden = NO;
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showCompleteButtonPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showCompleteButtonPopup"];
        DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.completeButton titles:@[@"完成制作视频的过程"] icons:nil menuWidth:120 delegate:self];
        normalBubble.showMaskAlpha = 1;
    }
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
    [DLYUserTrack recordAndEventKey:@"ExportViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"ExportView"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [DLYUserTrack recordAndEventKey:@"ExportViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"ExportView"];
}
#pragma mark - 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
}
- (void)deviceChangeAndHomeOnTheRight {
    
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
}

@end

