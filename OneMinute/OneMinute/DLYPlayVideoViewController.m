//
//  DLYPlayVideoViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYPlayVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DLYExportViewController.h"
#import "DLYResource.h"

#define SWitdh [UIScreen mainScreen].bounds.size.width
#define SHeight [UIScreen mainScreen].bounds.size.height

@interface DLYPlayVideoViewController ()
{
    BOOL isPlay;  //记录播放还是暂停
}

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 播放器对象 */
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) id progressObserver;
@property (nonatomic, strong) UIButton *playButton;

@end

@implementation DLYPlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self setupUI];
    
    //即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}
- (void)setupUI{
    
    //创建播放器层
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
//    NSURL *url = [NSURL fileURLWithPath:path];
//    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    
    self.playerItem = [AVPlayerItem playerItemWithURL:self.playUrl];

    
    [self addObserverToPlayItem:self.playerItem];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.frame;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.view.layer addSublayer:self.playerLayer];
    
    isPlay = YES;
    //    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SWitdh, SHeight)];
    //    imageView.image = [UIImage imageNamed:@"timg"];
    //    [self.view addSubview:imageView];
    //返回
    UIButton * backButton = [[UIButton alloc]initWithFrame:CGRectMake(28, 0, 60, 60)];
    backButton.centerY = self.view.centerY;
    backButton.layer.cornerRadius = 30;
    backButton.clipsToBounds = YES;
    backButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    backButton.tag = 10;
    [backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    [backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    //播放
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.playButton.layer.cornerRadius = 30;
    self.playButton.clipsToBounds = YES;
    self.playButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.playButton.tag = 11;
    [self.playButton addTarget:self action:@selector(onClickPlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66a" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.center = self.view.center;
    [self.view addSubview:self.playButton];
    //下一步
    
    if (self.isAll) {
        UIButton * nextButton = [[UIButton alloc]initWithFrame:CGRectMake(SWitdh - 82, 0, 60, 60)];
        nextButton.backgroundColor = RGB(255, 0, 0);
        nextButton.centerY = self.view.centerY;
        nextButton.layer.cornerRadius = 30;
        nextButton.clipsToBounds = YES;
        [nextButton setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        nextButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        [nextButton addTarget:self action:@selector(onClickNext) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:nextButton];
    }
    
    self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    //设置的高度对进度条的高度没影响，整个高度=进度条的高度，进度条也是个圆角矩形
    //但slider滑动控件：设置的高度对slider也没影响，但整个高度=设置的高度，可以设置背景来检验
    self.progress.frame = CGRectMake(32, SHeight - 45, SWitdh - 64, 2);
    //设置进度条颜色
    self.progress.trackTintColor = [UIColor whiteColor];
    //设置进度默认值，这个相当于百分比，范围在0~1之间，不可以设置最大最小值
    self.progress.progress = 0;
    //设置进度条上进度的颜色
    self.progress.progressTintColor = [UIColor redColor];
    [self.progress setProgress:0.0 animated:YES];
    [self.view addSubview:self.progress];
}

- (void)onClickBack:(UIButton *)sender{
    
    [MobClick event:@"BackView"];
    //返回
    if(self.DismissBlock){
        self.DismissBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];

    
}

- (void)onClickPlayOrPause:(UIButton *)sender {
    
    [MobClick event:@"PlayOrPause"];
    if(isPlay)
    {//暂停
        
        [sender setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        [self.player pause];
    }else
    {//播放
        [sender setImage:[UIImage imageWithIcon:@"\U0000e66a" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        [self.player play];
    }
    isPlay = !isPlay;
    
}

- (void)onClickNext {
    
    DLYResource *resource = [[DLYResource alloc] init];
    [resource removeCurrentAllPart];
    //跳转下一步填写标题
    [self.player pause];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    
    DLYExportViewController *exportVC = [[DLYExportViewController alloc] init];
    [self.navigationController pushViewController:exportVC animated:YES];
}

- (void)addObserverToPlayItem:(AVPlayerItem *)playerItem {
    //监控状态属性: 注意AVPlayer也有一个status属性,通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}
#pragma mark - 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        NSLog(@"视频播放左转");
    }

}
- (void)deviceChangeAndHomeOnTheRight {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        NSLog(@"视频播放右转");
    }
}

#pragma mark - 播放完成通知
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

//即将进入后台，暂停视频
- (void)applicationWillResignActive {
    
    [self.player pause];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    
}

- (void)playbackFinished:(NSNotification *)notification {

    [self.player pause];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    
    if (self.isAll) {
        DLYResource *resource = [[DLYResource alloc] init];
        [resource removeCurrentAllPart];
        //跳转下一步填写标题
        DLYExportViewController *exportVC = [[DLYExportViewController alloc] init];
        [self.navigationController pushViewController:exportVC animated:YES];

    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    

}
#pragma mark - 页面将要显示
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"PlayVideoView"];
    if (self.newState == 1) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }else {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
}
#pragma mark - 播放进度监控
/**
 *	进度条监控
 */
- (void)addProgressObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    //这里每秒执行一次
    __weak typeof(self) weakSelf = self;
    _progressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(playerItem.duration);
//        NSLog(@"当前已经播放了%.2f",current);
        if (current) {
            [weakSelf.progress setProgress:(current / total) animated:YES];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
            //添加各种通知和观察者
            [self addNotification];
            [self addProgressObserver];
            [self.player play];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓存时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        NSLog(@"共缓存: %.2f",totalBuffer);
    }
    
}

#pragma mark - UI事件 播放和暂停\

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"PlayVideoView"];
    [self.player pause];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    
}

- (void)dealloc {
    NSLog(@"deallocdeallocdealloc我到底走了几遍几遍几遍");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:self.progressObserver];
    [self removeObserverFromPlayerItem:self.player.currentItem];
}

@end
