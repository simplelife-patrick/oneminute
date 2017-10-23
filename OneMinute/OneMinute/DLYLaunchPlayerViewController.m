//
//  DLYLaunchPlayerViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYLaunchPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "DLYBaseNavigationController.h"
#import "DLYRecordViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DLYLaunchPlayerViewController ()
/** 结束按钮 */
@property (nonatomic , strong)UIButton *enterMainButton;
@property (nonatomic,  strong)MPVolumeView *volumeView;

@end

@implementation DLYLaunchPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置界面
    [self setupView];
    //添加监听
    [self addNotification];
    //初始化视频
    [self prepareMovie];
    
}
#pragma mark -- 初始化视图逻辑
- (void)setupView {
    //进入应用button
    self.enterMainButton = [[UIButton alloc] init];
    _enterMainButton.frame = CGRectMake((SCREEN_WIDTH - 190) /2, SCREEN_HEIGHT - 32 - 50, 190, 50);
    _enterMainButton.layer.cornerRadius = 25;
    _enterMainButton.clipsToBounds = YES;
    _enterMainButton.backgroundColor = RGBA(0, 0, 0, 0.7);
    [_enterMainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_enterMainButton setTitle:@"开启Vlog" forState:UIControlStateNormal];
    [self.contentOverlayView addSubview:_enterMainButton];
    [_enterMainButton addTarget:self action:@selector(enterMainAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //音量
    _volumeView = [[MPVolumeView alloc]init];
    [_volumeView sizeToFit];
    [_volumeView userActivity];
    
    for (UIView* newView in _volumeView.subviews) {
        if ([newView.class.description isEqualToString:@"MPVolumeSlider"]){
            UISlider *volumeViewSlider = (UISlider*)newView;
            //            volumeViewSlider.value = 0.2;
            [volumeViewSlider setValue:0.1 animated:YES];
            [volumeViewSlider setValue:0.2 animated:YES];
            break;
        }
    }
}
#pragma mark -- 监听以及实现方法
- (void)addNotification {
    
    //即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    //视频播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
}
#pragma mark -- 初始化视频
- (void)prepareMovie {
    //首次运行
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PromoteVideo.mp4" ofType:nil];
    //初始化player
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    //视频填充模式 充满
    self.videoGravity = AVLayerVideoGravityResize;
    self.showsPlaybackControls = NO;
    //静音下播放声音
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory:AVAudioSessionCategoryPlayback
                    error:&error];
    if (!success) {
        DLYLog(@"Could not use AVAudioSessionCategoryPlayback");
    }
    [self.player play];
}

#pragma mark -- 进入应用和显示进入按钮
- (void)enterMainAction:(UIButton *)btn {
    //视频暂停
    [self.player pause];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    DLYRecordViewController *vc = [[DLYRecordViewController alloc] init];
    DLYBaseNavigationController *nvc = [[DLYBaseNavigationController alloc] initWithRootViewController:vc];
    delegate.window.rootViewController = nvc;
    [delegate.window makeKeyWindow];
}

- (void)moviePlaybackEnd {
    
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

//即将进入后台，暂停视频
- (void)applicationWillResignActive {
    
    [self.player pause];
}
//即将进入前台
- (void)viewWillEnterForeground {
    DLYLog(@"app enter foreground");
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIViewController *vc = delegate.window.rootViewController;
    if (vc == self) {
        if (!self.player) {
            [self prepareMovie];
        }
        //播放视频
        [self.player play];
    }
}
#pragma mark -- 基本配置
//不允许旋转
- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [DLYUserTrack recordAndEventKey:@"LaunchViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"LaunchView"];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [DLYUserTrack recordAndEventKey:@"LaunchViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"LaunchView"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

