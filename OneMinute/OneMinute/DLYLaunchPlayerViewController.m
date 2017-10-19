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


@interface DLYLaunchPlayerViewController ()
/** 播放开始之前的图片 */
@property (nonatomic , strong)UIImageView *startPlayerImageView;
/** 播放中断时的图片 */
@property (nonatomic , strong)UIImageView *pausePlayerImageView;
/** 定时器 */
@property (nonatomic , strong)NSTimer *timer;
/** 结束按钮 */
@property (nonatomic , strong)UIButton *enterMainButton;


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
    self.startPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lauch"]];
    _startPlayerImageView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.contentOverlayView addSubview:_startPlayerImageView];
    
    //进入应用button
    self.enterMainButton = [[UIButton alloc] init];
    _enterMainButton.frame = CGRectMake((SCREEN_WIDTH - 190) /2, SCREEN_HEIGHT - 32 - 50, 190, 50);
    _enterMainButton.layer.cornerRadius = 25;
    _enterMainButton.clipsToBounds = YES;
    _enterMainButton.backgroundColor = RGBA(0, 0, 0, 0.7);
    [_enterMainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_enterMainButton setTitle:@"开启Vlog" forState:UIControlStateNormal];
    _enterMainButton.hidden = YES;
    [self.view addSubview:_enterMainButton];
    [_enterMainButton addTarget:self action:@selector(enterMainAction:) forControlEvents:UIControlEventTouchUpInside];
}
#pragma mark -- 监听以及实现方法
- (void)addNotification {
    
    //即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    //视频播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //播放开始
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStart) name:AVPlayerItemTimeJumpedNotification object:nil];
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
        NSLog(@"Could not use AVAudioSessionCategoryPlayback");
    }
    [self.player play];
}

#pragma mark -- 进入应用和显示进入按钮
- (void)enterMainAction:(UIButton *)btn {
    //视频暂停
    [self.player pause];
    self.pausePlayerImageView = [[UIImageView alloc] init];
    _pausePlayerImageView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.contentOverlayView addSubview:_pausePlayerImageView];
    self.pausePlayerImageView.contentMode = UIViewContentModeScaleToFill;
    //获取当前暂停时的截图
    [self getoverPlayerImage];
}
- (void)getoverPlayerImage {
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:self.player.currentItem.asset];
    gen.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CMTime actualTime;
    CMTime now = self.player.currentTime;
    [gen setRequestedTimeToleranceAfter:kCMTimeZero];
    [gen setRequestedTimeToleranceBefore:kCMTimeZero];
    CGImageRef image = [gen copyCGImageAtTime:now actualTime:&actualTime error:&error];
    if (!error) {
        UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
        self.pausePlayerImageView.image = thumb;
    }
    DLYLog(@"%f , %f",CMTimeGetSeconds(now),CMTimeGetSeconds(actualTime));
    DLYLog(@"%@",error);
    //视频播放结束
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moviePlaybackComplete];
    });
    
}
//进入主界面
- (void)enterMain {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    DLYRecordViewController *vc = [[DLYRecordViewController alloc] init];
    DLYBaseNavigationController *nvc = [[DLYBaseNavigationController alloc] initWithRootViewController:vc];
    delegate.window.rootViewController = nvc;
    [delegate.window makeKeyWindow];
}
//开始播放
- (void)moviePlaybackStart {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.startPlayerImageView removeFromSuperview];
        self.startPlayerImageView = nil;
    });
}

- (void)moviePlaybackEnd {
    
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
    if (_enterMainButton.isHidden) {
        _enterMainButton.hidden = NO;
     [self.view bringSubviewToFront:_enterMainButton];
    }
}

//进入主界面，对视频做完成操作
- (void)moviePlaybackComplete {
    //发送推送之后就删除  否则 界面显示有问题
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    
    [self.startPlayerImageView removeFromSuperview];
    self.startPlayerImageView = nil;
    
    [self.pausePlayerImageView removeFromSuperview];
    self.pausePlayerImageView = nil;
    
    if (self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    //进入主界面
    [self enterMain];
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
//不允许旋转
- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer invalidate];
    self.timer = nil;
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
