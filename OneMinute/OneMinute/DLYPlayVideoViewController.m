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
#import "DLYRecordViewController.h"
#import "DLYAVEngine.h"
#import "DLYSession.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define kMaxLength 16

@interface DLYPlayVideoViewController ()<UITextFieldDelegate,UIGestureRecognizerDelegate,DLYCaptureAVEngineDelegate,YBPopupMenuDelegate>
{
    float mRestoreAfterScrubbingRate;
    //1.流量 2.WiFi 3.不可用
    NSInteger statusNum;
    id _timeObserver;
}
@property (nonatomic, strong) DLYAVEngine *AVEngine;
@property (nonatomic, strong) DLYResource  *resource;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 播放器对象 */
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UILabel *currentLabel;
@property (nonatomic, strong) UILabel *durationLabel;
//控件
@property (nonatomic, strong) UIActivityIndicatorView *waitIndicator;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *backButton;
//标题
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UIButton *skipTestBtn;
@property (nonatomic, strong) UIView *backView;
//网络监测
@property (nonatomic, strong) AFNetworkReachabilityManager *manager;
@property (nonatomic, strong) DLYAlertView *alert;

@property (nonatomic, assign) BOOL isCanOnlinePlay; //准备好了可以播放
@property (nonatomic, assign) BOOL isSurePlay;      //确定流量播放
@property (nonatomic, strong) UIImage *frameImage;
@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSArray                *moviePathArray;

@property (nonatomic, strong) NSMutableArray *viewArr;      //视图数组
@property (nonatomic, strong) NSMutableArray *bubbleTitleArr;//视图数组

@end

@implementation DLYPlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isOnline) {
        [self monitorNetWork];
    }
    
    if (!self.isSuccess && self.isAll) {
        [self initializationRecorder];
        [self createMainView];
    }else {
        //这个页面 先不加载
        [self setupUI];
    }
    
    //即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(canPlayVideo:) name:@"CANPLAY" object:nil];
}
#pragma mark ---- 气泡
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (!self.isSuccess && self.isAll) {
        [self showCueBubble];
    }
}

- (void)showCueBubble {
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"DLYPlayViewPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DLYPlayViewPopup"];
        NSArray *arr = @[self.titleField, self.skipButton, self.skipTestBtn];
        self.viewArr = [NSMutableArray arrayWithArray:arr];
        NSArray *titleArr = @[@"输入描述文字", @"去完成视频", @"跳过输入文字操作"];
        self.bubbleTitleArr = [NSMutableArray arrayWithArray:titleArr];
        [self showPopupMenu];
    }
}

- (void)showPopupMenu {
    
    if (self.viewArr.count == 0) {
        [self.titleField becomeFirstResponder];
        return;
    }
    UIView *view = self.viewArr[0];
    NSString *title = self.bubbleTitleArr[0];
    NSArray *titles = @[title];
    DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:view titles:titles icons:nil menuWidth:120 delegate:self];
    normalBubble.showMaskAlpha = 1;
    [self.viewArr removeObjectAtIndex:0];
    [self.bubbleTitleArr removeObjectAtIndex:0];
}
//气泡消失的代理方法
- (void)ybPopupMenuDidDismiss {
    [self showPopupMenu];
}

#pragma mark ==== 初始化相机
- (void)initializationRecorder {
    
    self.AVEngine = [[DLYAVEngine alloc] init];
    self.AVEngine.delegate = self;
}
- (void)didFinishEdititProductUrl:(NSURL *)productUrl{
    
    NSDictionary *dict = @{@"playUrl":self.AVEngine.currentProductUrl};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CANPLAY" object:nil userInfo:dict];

    [DLYUserTrack recordAndEventKey:@"MergeVideoFinish"];
    self.AVEngine.finishOperation = [self.AVEngine getDateTimeTOMilliSeconds:[NSDate date]];
    NSString *str = [NSString stringWithFormat:@"成片耗时%lld秒", (self.AVEngine.finishOperation - self.AVEngine.startOperation)/1000];
    [DLYUserTrack recordAndEventKey:@"MergeConsumeTime" andDescribeStr:str];
}
- (void)createMainView {
    NSURL *url = [self.resource getPartUrlWithPartNum:0];
    UIImage *frameImage = [self.AVEngine getKeyImage:url intervalTime:2.0];
    self.frameImage = frameImage;
    UIImageView * videoImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    videoImage.image = frameImage;
    [self.view addSubview:videoImage];
    
    self.backView = [[UIView alloc] initWithFrame:self.view.frame];
    self.backView.backgroundColor = RGBA(0, 0, 0, 0);
    [self.view addSubview:self.backView];
    
    //标题输入框
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 370, 42)];
    self.titleField.center = self.view.center;
    self.titleField.delegate = self;
    
    //    NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"videoTitle"];
    //    NSString *newStr = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    //    if (newStr.length == 0) {
    //        self.titleField.placeholder = @"请输入标题";
    //    }else {
    //        self.titleField.text = text;
    //    }
    self.titleField.placeholder = @"请输入标题";
    self.titleField.textAlignment = NSTextAlignmentCenter;
    [self.titleField setValue:RGBA(255, 255, 255, 0.7) forKeyPath:@"_placeholderLabel.textColor"];
    self.titleField.tintColor = RGBA(255, 255, 255, 0.7);
    self.titleField.font = FONT_SYSTEM(40);
    self.titleField.textColor = RGBA(255, 255, 255, 0.7);
    self.titleField.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:self.titleField];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"DLYPlayViewPopup"]){
        [self.titleField becomeFirstResponder];
    }
    [self.titleField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    //跳过button
    self.skipButton = [[UIButton alloc] initWithFrame:CGRectMake(582 * SCALE_WIDTH, 158 * SCALE_HEIGHT, 60 * SCALE_WIDTH, 60 * SCALE_WIDTH)];
    [self.skipButton setImage:[UIImage imageWithIconName:IFSuccessful inFont:ICONFONT size:30 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.skipButton.backgroundColor = RGB(255, 0, 0);
    self.skipButton.layer.cornerRadius = 30 * SCALE_WIDTH;
    self.skipButton.clipsToBounds = YES;
    [self.skipButton addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipButton];
    
    //跳过button
    self.skipTestBtn = [[UIButton alloc] initWithFrame:CGRectMake(599.5 * SCALE_WIDTH, self.skipButton.bottom + 30, 44, 44)];
    self.skipTestBtn.backgroundColor = RGBA(0, 0, 0, 0.3);
    self.skipTestBtn.layer.cornerRadius = 22;
    self.skipTestBtn.clipsToBounds = YES;
    [self.skipTestBtn setTitle:@"跳过" forState:UIControlStateNormal];
    [self.skipTestBtn setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.skipTestBtn.titleLabel.font = FONT_SYSTEM(14);
    self.skipTestBtn.centerX = self.skipButton.centerX;
    [self.skipTestBtn addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipTestBtn];
    
    //监听键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeContentViewPosition:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidechangeContentViewPosition:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)onClickSkip {
    [self.view  endEditing:YES];
    [self makeVideo];
}

- (void)makeVideo {
    
    NSString *newStr = [self.titleField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (newStr.length == 0) {
        [DLYUserTrack recordAndEventKey:@"Skip"];
    }else {
        [DLYUserTrack recordAndEventKey:@"Skip" andDescribeStr:self.titleField.text];
    }
    
    //隐藏所有控件
    self.backView.hidden = YES;
    self.titleField.hidden = YES;
    self.skipButton.hidden = YES;
    self.skipTestBtn.hidden = YES;
    //创建view
    [self setupUI];
    //获取开始时刻统计合成耗时
    self.AVEngine.startOperation = [self.AVEngine getDateTimeTOMilliSeconds:[NSDate date]];
    
    typeof(self) weakSelf = self;
    [self.AVEngine addVideoHeaderWithTitle:self.titleField.text successed:^{
        
        weakSelf.AVEngine.finishOperation = [weakSelf.AVEngine getDateTimeTOMilliSeconds:[NSDate date]];
        DLYLog(@"成片耗时: %lld s",(weakSelf.AVEngine.finishOperation - weakSelf.AVEngine.startOperation)/1000);
    } failured:^(NSError *error) {
        
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view == self.progressSlider ) {
        return NO;
    }else {
        return YES;
    }
}

- (void)setupUI{
    //创建播放器层
    self.view.backgroundColor = RGB(0, 0, 0);
    self.playerItem = [AVPlayerItem playerItemWithURL:self.playUrl];
    
    if ((self.isSuccess && self.isAll) || (!self.isAll)) {
        [self addObserverToPlayItem:self.playerItem];
    }
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.frame;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    //    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    [self.view.layer addSublayer:self.playerLayer];
    
    //返回
    self.backButton = [[UIButton alloc]initWithFrame:CGRectMake(28, 0, 60, 60)];
    self.backButton.centerY = self.view.centerY;
    self.backButton.layer.cornerRadius = 30;
    self.backButton.clipsToBounds = YES;
    self.backButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.backButton.tag = 10;
    [self.backButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    self.backButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    [self.backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    //播放
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.playButton.layer.cornerRadius = 30;
    self.playButton.clipsToBounds = YES;
    self.playButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.playButton.tag = 11;
    [self.playButton addTarget:self action:@selector(onClickPlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setImage:[UIImage imageWithIconName:IFStopVideo inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.center = self.view.center;
    [self.view addSubview:self.playButton];
    
    //下一步
    if (self.isAll) {
        self.nextButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 82, 0, 60, 60)];
        self.nextButton.backgroundColor = RGB(255, 0, 0);
        self.nextButton.centerY = self.view.centerY;
        self.nextButton.layer.cornerRadius = 30;
        self.nextButton.clipsToBounds = YES;
        [self.nextButton setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
        self.nextButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        [self.nextButton addTarget:self action:@selector(onClickNext) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.nextButton];
        if (self.isSuccess) {
            self.nextButton.hidden = NO;
        }else {
            self.nextButton.hidden = YES;
        }
    }
    //这里要改1
    if (self.isOnline) {
        self.waitIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.waitIndicator.frame = CGRectMake(0, 0, 65, 65);
        self.waitIndicator.center = self.view.center;
        [self.view addSubview:self.waitIndicator];
        [self.waitIndicator startAnimating];
    }
    if (self.isAll && self.isSuccess == NO) {
        [[DLYIndicatorView sharedIndicatorView] startFlashAnimatingWithTitle:@"处理中,请稍后"];
    }
    //滑块
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(85, SCREEN_HEIGHT - 45, SCREEN_WIDTH - 170, 20)];
    self.progressSlider.centerY = SCREEN_HEIGHT - 44;
    self.progressSlider.maximumTrackTintColor = [UIColor whiteColor];
    self.progressSlider.minimumTrackTintColor = [UIColor redColor];
    self.progressSlider.continuous = NO;
    self.progressSlider.value = 0.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"plthumb"] forState:UIControlStateNormal];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"plthumb"] forState:UIControlStateHighlighted];
    [self.progressSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [self.progressSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [self.view addSubview:self.progressSlider];
    
    //当前时间
    self.currentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 14)];
    self.currentLabel.centerY = SCREEN_HEIGHT - 44;
    self.currentLabel.right = self.progressSlider.left - 13;
    [self.view addSubview:self.currentLabel];
    self.currentLabel.font = [UIFont systemFontOfSize:12];
    self.currentLabel.textColor = RGB(255, 255, 255);
    self.currentLabel.textAlignment = NSTextAlignmentRight;
    self.currentLabel.text = @"00:00";
    
    //总时间
    self.durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 14)];
    self.durationLabel.centerY = SCREEN_HEIGHT - 44;
    self.durationLabel.left = self.progressSlider.right + 13;
    [self.view addSubview:self.durationLabel];
    self.durationLabel.font = [UIFont systemFontOfSize:12];
    self.durationLabel.textColor = RGB(255, 255, 255);
    self.durationLabel.textAlignment = NSTextAlignmentLeft;
    self.durationLabel.text = @"00:00";
    
    if ([DLYIndicatorView sharedIndicatorView].isFlashAnimating) {
        self.progressSlider.hidden = YES;
        self.currentLabel.hidden = YES;
        self.durationLabel.hidden = YES;
        self.backButton.hidden = YES;
        self.playButton.hidden = YES;
    }
    if (self.waitIndicator.isAnimating) {
        self.playButton.hidden = YES;
    }
    
    //手势
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls:)];
    singleTap.delegate = self;
    [self.view addGestureRecognizer:singleTap];
}

- (void)onClickBack:(UIButton *)sender{
    
    [DLYUserTrack recordAndEventKey:@"BackView"];
    //返回
    if(self.DismissBlock){
        self.DismissBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickPlayOrPause:(UIButton *)sender {
    
    [DLYUserTrack recordAndEventKey:@"PlayOrPause"];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if([self isPlaying])
    {//之前是播放那就暂停 显示暂停图标
        [self pause];
    }else
    {//之前是暂停那就播放 显示播放图标
        [self play];
    }
}

- (void)onClickNext {
    //跳转下一步填写标题
    [self pause];
    DLYExportViewController *exportVC = [[DLYExportViewController alloc] init];
    exportVC.beforeState = self.newState;
    exportVC.backImage = self.frameImage;
    [self.navigationController pushViewController:exportVC animated:YES];
}

- (void)addObserverToPlayItem:(AVPlayerItem *)playerItem {
    //监控状态属性: 注意AVPlayer也有一个status属性,通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 缓冲区空了，需要等待数据
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:nil];
    // 缓冲区有足够数据可以播放了
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}
#pragma mark ==== 网络监测
- (void)monitorNetWork {
    
    // 1.获得网络监控的管理者
    _manager = [AFNetworkReachabilityManager sharedManager];
    // 2.设置网络状态改变后的处理
    __weak typeof(self) weakSelf = self;
    [_manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
            statusNum = AFNetworkReachabilityStatusReachableViaWWAN;
            //            DLYLog(@"当前处于非WIFI状态");
            [weakSelf pause];
            [weakSelf hideControlsFast];
            weakSelf.alert = [[DLYAlertView alloc] initWithMessage:@"当前处于非WIFI状态\n是否继续观看?" andCancelButton:@"取消" andSureButton:@"确定"];
            weakSelf.alert.sureButtonAction = ^{
                if (weakSelf.isCanOnlinePlay) {
                    [weakSelf play];
                }else {
                    weakSelf.isSurePlay = YES;
                }
            };
            weakSelf.alert.cancelButtonAction = ^{
            };
            
        }else if (status == AFNetworkReachabilityStatusUnknown || status == AFNetworkReachabilityStatusNotReachable){
            statusNum = -1;
            //            DLYLog(@"当前无可用网络,请联网后播放");
            weakSelf.alert = [[DLYAlertView alloc] initWithMessage:@"当前无可用网络,请联网后播放" withSureButton:@"确定"];
            weakSelf.alert.sureButtonAction = ^{
                
            };
        }else if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
            statusNum = AFNetworkReachabilityStatusReachableViaWiFi;
        }
    }];
    // 3.开始监控
    [_manager startMonitoring];
    
}
#pragma mark ==== 播放器控制
- (void)beginScrubbing:(UISlider *)sender {
    mRestoreAfterScrubbingRate = [self.player rate];
    [self.player setRate:0.f];
    
    [self removePlayerTimeObserver];
}
- (void)scrub:(UISlider *)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            if (time == duration) {
                
                [_player seekToTime:kCMTimeZero];
                [_player play];
                
            }else{
                __weak typeof(self) weakSelf = self;
                [_player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
                    if (finished == YES) {
                        //转菊花
                        if (self.isOnline) {
                            [self.waitIndicator stopAnimating];
                            self.playButton.hidden = NO;
                        }
                        //播放
                        [weakSelf play];
                    }
                }];
                //转菊花
                if (self.isOnline) {
                    [self.waitIndicator startAnimating];
                    self.playButton.hidden = YES;
                }
            }
        }
    }
}
- (void)endScrubbing:(UISlider *)sender {
    if (!_timeObserver) {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            CGFloat width = CGRectGetWidth([_progressSlider bounds]);
            double tolerance = 0.5f * duration / width;
            
            __weak typeof(self) weakSelf = self;
            _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                             ^(CMTime time)
                             {
                                 [weakSelf syncScrubber];
                             }];
        }
    }
    
    if (mRestoreAfterScrubbingRate) {
        [_player setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

- (void)initScrubberTimer {
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([_progressSlider bounds]);
        interval = 0.5f * duration / width;
    }
    
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncScrubber];
    }];
}
- (void)syncScrubber {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        _progressSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [_progressSlider minimumValue];
        float maxValue = [_progressSlider maximumValue];
        double time = CMTimeGetSeconds([_player currentTime]);
        
        [_progressSlider setValue:(maxValue - minValue) * time / duration + minValue animated:YES];
        self.currentLabel.text = [self formatTimeToString:time];
        self.durationLabel.text = [self formatTimeToString:duration];
    }
}

#pragma mark 转成时间字符串
-(NSString *)formatTimeToString:(NSTimeInterval)time{
    //    NSInteger hours = time/3600;
    NSInteger minutes = (NSInteger)time%3600/60;
    NSInteger seconds = (NSInteger)time%60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)enableScrubber {
    _progressSlider.enabled = YES;
}
- (void)disableScrubber {
    _progressSlider.enabled = NO;
}

- (void)removePlayerTimeObserver {
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}
//考虑菊花
- (void)enablePlayerButtons {
    _playButton.enabled = YES;
}
//考虑菊花
- (void)disablePlayerButtons {
    _playButton.enabled = NO;
}
- (CMTime)playerItemDuration {
    
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        
        return([self.playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}
- (BOOL)isPlaying {
    return mRestoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}
- (void)play {
    [self.player play];
    [self.playButton setImage:[UIImage imageWithIconName:IFStopVideo inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self scheduleHideControls];
}
- (void)pause {
    [self.player pause];
    [self.playButton setImage:[UIImage imageWithIconName:IFPlayVideo inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self scheduleHideControls];
}
#pragma mark ==== 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
    
}
- (void)deviceChangeAndHomeOnTheRight {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
}

#pragma mark ==== 播放完成通知
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

//即将进入后台，暂停视频
- (void)applicationWillResignActive {
    [self pause];
}

- (void)playbackFinished:(NSNotification *)notification {
    
    [self pause];
    if (self.isAll) {
        //跳转下一步填写标题
        DLYExportViewController *exportVC = [[DLYExportViewController alloc] init];
        exportVC.beforeState = self.newState;
        exportVC.backImage = self.frameImage;
        [self.navigationController pushViewController:exportVC animated:YES];
        
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark ==== 页面将要显示
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [DLYUserTrack recordAndEventKey:@"PlayVideoViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"PlayVideoView"];
}
#pragma mark ==== 播放进度监控

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            //添加各种通知和观察者
            [self addNotification];
            //            [self addProgressObserver];
            if ([DLYIndicatorView sharedIndicatorView].isFlashAnimating) {
                [[DLYIndicatorView sharedIndicatorView] stopFlashAnimating];
                self.backButton.hidden = NO;
                self.progressSlider.hidden = NO;
                self.currentLabel.hidden = NO;
                self.durationLabel.hidden = NO;
                self.playButton.hidden = NO;
            }
            if (self.waitIndicator.isAnimating) {
                [self.waitIndicator stopAnimating];
                self.playButton.hidden = NO;
            }
            if (self.isAll) {
                self.nextButton.hidden = NO;
            }
            self.isCanOnlinePlay = YES;
            if (self.isOnline) {
                if ((statusNum == 1 && self.isSurePlay) || (statusNum == 2)) {
                    [self initScrubberTimer];
                    [self enablePlayerButtons];
                    [self enableScrubber];
                    [self play];
                }
            }else {
                [self initScrubberTimer];
                [self enablePlayerButtons];
                [self enableScrubber];
                [self play];
            }
            
        }else if (playerItem.status == AVPlayerItemStatusUnknown){
            [self removePlayerTimeObserver];
            [self syncScrubber];
            [self disableScrubber];
            [self disablePlayerButtons];
            
        }else if (playerItem.status == AVPlayerItemStatusFailed) {
            [self removePlayerTimeObserver];
            [self syncScrubber];
            [self disableScrubber];
            [self disablePlayerButtons];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //        NSArray *array = playerItem.loadedTimeRanges;
        //        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓存时间范围
        //        float startSeconds = CMTimeGetSeconds(timeRange.start);
        //        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        //        DLYLog(@"共缓存: %.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        //        [self.loadingView startAnimating];
        // 当缓冲是空的时候
        //        if (self.playerItem.playbackBufferEmpty) {
        //            DLYLog(@"缓存为空");
        //            [self loadedTimeRanges];
        //        }
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        //        [self.loadingView stopAnimating];
        // 当缓冲好的时候
        //        if (self.playerItem.playbackLikelyToKeepUp && self.state == WMPlayerStateBuffering){
        //            DLYLog(@"55555%s WMPlayerStatePlaying",__FUNCTION__);
        //            self.state = WMPlayerStatePlaying;
        //        }
    }
    
}

- (void)canPlayVideo:(NSNotification *)notification {
    if (self.isAll) {
        
        if (self.playUrl == nil || self.playUrl.path.length <= 0) {
            self.playUrl = notification.userInfo[@"playUrl"];
        }
        
        self.playerItem = [AVPlayerItem playerItemWithURL:self.playUrl];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self addObserverToPlayItem:self.playerItem];
    }
}

#pragma mark ==== 键盘监听
//监听 键盘将要显示
- (void)changeContentViewPosition:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat height = value.CGRectValue.size.height;
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    CGRect rect = self.titleField.frame;
    CGFloat a = self.view.bounds.size.width;
    CGFloat b = self.view.bounds.size.height;
    
    CGFloat min = a < b ? a : b;
    rect.origin.y = (min - height - rect.size.height) / 2;
    [UIView animateWithDuration:duration.doubleValue animations:^{
        self.backView.backgroundColor = RGBA(0, 0, 0, 0.5);
        self.titleField.frame = rect;
    }];
}
//监听 键盘将要隐藏
- (void)hidechangeContentViewPosition:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    //回归位置
    [UIView animateWithDuration:duration.doubleValue animations:^{
        self.backView.backgroundColor = RGBA(0, 0, 0, 0);
        self.titleField.center = self.view.center;
    }];
    
}
//按下Return时调用
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view  endEditing:YES];
    [self makeVideo];
    return YES;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
#pragma mark ==== 限制输入字数
- (void)textFieldDidChange:(UITextField *)textField {
    NSString *toBeString = textField.text;
    
    if (![self isInputRuleAndBlank:toBeString]) {
        textField.text = [self disable_emoji:toBeString];
        return;
    }
    
    NSString *lang = [[textField textInputMode] primaryLanguage]; // 获取当前键盘输入模式
    //    DLYLog(@"%@",lang);
    if([lang isEqualToString:@"zh-Hans"]) { //简体中文输入,第三方输入法（搜狗）所有模式下都会显示“zh-Hans”
        UITextRange *selectedRange = [textField markedTextRange];
        //获取高亮部分
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        //没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if(!position) {
            NSString *getStr = [self getSubString:toBeString];
            if(getStr && getStr.length > 0) {
                textField.text = getStr;
            }
        }
    } else{
        NSString *getStr = [self getSubString:toBeString];
        if(getStr && getStr.length > 0) {
            textField.text= getStr;
        }
    }
}
// 字母、数字、中文正则判断（包括空格）（在系统输入法中文输入时会出现拼音之间有空格，需要忽略，当按return键时会自动用字母替换，按空格输入响应汉字）
- (BOOL)isInputRuleAndBlank:(NSString *)str {
    
    NSString *pattern = @"^[a-zA-Z\u4E00-\u9FA5\\d\\s]*$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatch = [pred evaluateWithObject:str];
    return isMatch;
}
// 获得 kMaxLength长度的字符
- (NSString *)getSubString:(NSString*)string {
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* data = [string dataUsingEncoding:encoding];
    NSInteger length = [data length];
    if (length > kMaxLength) {
        NSData *data1 = [data subdataWithRange:NSMakeRange(0, kMaxLength)];
        NSString *content = [[NSString alloc] initWithData:data1 encoding:encoding];//注意：当截取kMaxLength长度字符时把中文字符截断返回的content会是nil
        if (!content || content.length == 0) {
            data1 = [data subdataWithRange:NSMakeRange(0, kMaxLength - 1)];
            content =  [[NSString alloc] initWithData:data1 encoding:encoding];
        }
        return content;
    }
    return nil;
}
- (NSString *)disable_emoji:(NSString *)text{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]"options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:text
                                                               options:0
                                                                 range:NSMakeRange(0, [text length])
                                                          withTemplate:@""];
    return modifiedString;
}

#pragma mark ==== 控件显隐

- (void)toggleControls:(UITapGestureRecognizer *)recognizer {
    //转菊花判断
    if ([DLYIndicatorView sharedIndicatorView].isFlashAnimating) {
        return;
    }else {
        if(self.progressSlider.isHidden){
            [self showControlsFast];
        }else{
            [self hideControlsFast];
        }
        
        [self scheduleHideControls];
    }
}

//1快速显示
- (void)showControlsFast {
    
    self.playButton.alpha = 0.0;
    self.playButton.hidden = NO;
    
    if (self.nextButton) {
        self.nextButton.alpha = 0.0;
        self.nextButton.hidden = NO;
    }
    
    self.backButton.alpha = 0.0;
    self.backButton.hidden = NO;
    
    self.progressSlider.alpha = 0.0;
    self.progressSlider.hidden = NO;
    
    self.currentLabel.alpha = 0.0;
    self.currentLabel.hidden = NO;
    
    self.durationLabel.alpha = 0.0;
    self.durationLabel.hidden = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.playButton.alpha = 1.0;
        self.backButton.alpha = 1.0;
        self.progressSlider.alpha = 1.0;
        self.currentLabel.alpha = 1.0;
        self.durationLabel.alpha = 1.0;
        if (self.nextButton) {
            self.nextButton.alpha = 1.0;
        }
    }];
    
}
//2快速隐藏
- (void)hideControlsFast {
    [self hideControlsWithDuration:0.2];
}
//3慢隐藏
- (void)hideControlsSlowly {
    [self hideControlsWithDuration:0.5];
}
//4隐藏操作
- (void)hideControlsWithDuration:(NSTimeInterval)duration {
    self.playButton.alpha = 1.0;
    self.backButton.alpha = 1.0;
    self.progressSlider.alpha = 1.0;
    self.currentLabel.alpha = 1.0;
    self.durationLabel.alpha = 1.0;
    if (self.nextButton) {
        self.nextButton.alpha = 1.0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.playButton.alpha = 0.0;
        self.backButton.alpha = 0.0;
        self.progressSlider.alpha = 0.0;
        self.currentLabel.alpha = 0.0;
        self.durationLabel.alpha = 0.0;
        if (self.nextButton) {
            self.nextButton.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        self.playButton.hidden = YES;
        self.backButton.hidden = YES;
        self.progressSlider.hidden = YES;
        self.currentLabel.hidden = YES;
        self.durationLabel.hidden = YES;
        if (self.nextButton) {
            self.nextButton.hidden = YES;
        }
    }];
    
}
//5
- (void)scheduleHideControls {
    if(!self.progressSlider.isHidden) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideControlsSlowly) withObject:nil afterDelay:3.0];
    }
}

#pragma mark ==== UI事件 播放和暂停

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    if (self.waitIndicator.isAnimating) {
        [self.waitIndicator stopAnimating];
    }
    
    [DLYUserTrack recordAndEventKey:@"PlayVideoViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"PlayVideoView"];
    [_manager stopMonitoring];
    [self pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    @try {
        [self removePlayerTimeObserver];
    } @catch(id anException) {
        //do nothing
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CANPLAY" object:nil];
    //    [[NSUserDefaults standardUserDefaults] setObject:self.titleField.text forKey:@"videoTitle"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:_timeObserver];
    [self removeObserverFromPlayerItem:self.player.currentItem];
}

#pragma mark ==== 懒加载
- (DLYResource *)resource{
    if (!_resource) {
        _resource = [[DLYResource alloc] init];
    }
    return _resource;
}

@end

