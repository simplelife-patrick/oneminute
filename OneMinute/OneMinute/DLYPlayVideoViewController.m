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


#define SWitdh [UIScreen mainScreen].bounds.size.width
#define SHeight [UIScreen mainScreen].bounds.size.height

@interface DLYPlayVideoViewController ()<UITextFieldDelegate>
{
    BOOL isPlay;  //记录播放还是暂停
}
@property (nonatomic, strong) DLYAVEngine *AVEngine;
@property (nonatomic, strong) DLYResource  *resource;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/** 播放器对象 */
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) id progressObserver;
@property (nonatomic, strong) UIButton *playButton;
//控件
@property (nonatomic, strong) UIActivityIndicatorView *waitIndicator;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *backButton;
//标题
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UIButton *skipTestBtn;
@property (nonatomic, strong) UIView *backView;

@end

@implementation DLYPlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

#pragma mark - 初始化相机
- (void)initializationRecorder {
    
    self.AVEngine = [[DLYAVEngine alloc] init];
}

- (void)createMainView {
    NSURL *url = [self.resource getPartUrlWithPartNum:0];
    UIImage *frameImage = [self.AVEngine getKeyImage:url intervalTime:2.0];
    
    UIImageView * videoImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SWitdh, SHeight)];
    videoImage.image = frameImage;
    [self.view addSubview:videoImage];
    
    self.backView = [[UIView alloc] initWithFrame:self.view.frame];
    self.backView.backgroundColor = RGBA(0, 0, 0, 0);
    [self.view addSubview:self.backView];
    
    //标题输入框
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 320, 42)];
    self.titleField.center = self.view.center;
    self.titleField.delegate = self;
    
    NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"videoTitle"];
    NSString *newStr = [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (newStr.length == 0) {
        self.titleField.placeholder = @"请输入标题";
    }else {
        self.titleField.text = text;
    }
    self.titleField.textAlignment = NSTextAlignmentCenter;
    [self.titleField setValue:RGB(255, 255, 255) forKeyPath:@"_placeholderLabel.textColor"];
    self.titleField.tintColor = RGB(255, 255, 255);
    self.titleField.font = FONT_SYSTEM(40);
    self.titleField.textColor = RGB(255, 255, 255);
    [self.view addSubview:self.titleField];
    [self.titleField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    //跳过button
    self.skipButton = [[UIButton alloc] initWithFrame:CGRectMake(582 * SCALE_WIDTH, 158 * SCALE_HEIGHT, 60 * SCALE_WIDTH, 60 * SCALE_WIDTH)];
    [self.skipButton setImage:[UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:30 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.skipButton.backgroundColor = RGB(255, 0, 0);
    self.skipButton.layer.cornerRadius = 30 * SCALE_WIDTH;
    self.skipButton.clipsToBounds = YES;
    [self.skipButton addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipButton];
    
    //跳过button
    self.skipTestBtn = [[UIButton alloc] init];
    [self.skipTestBtn setTitle:@"跳过" forState:UIControlStateNormal];
    [self.skipTestBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.skipTestBtn.titleLabel.font = FONT_SYSTEM(14);
    [self.skipTestBtn sizeToFit];
    self.skipTestBtn.frame = CGRectMake(599.5 * SCALE_WIDTH, self.skipButton.bottom + 3, self.skipTestBtn.width, self.skipTestBtn.height);
    self.skipTestBtn.centerX = self.skipButton.centerX;
    [self.skipTestBtn addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipTestBtn];
    
    //监听键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeContentViewPosition:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidechangeContentViewPosition:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)onClickSkip {
    
    [MobClick event:@"Skip"];
    //隐藏所有控件
    self.backView.hidden = YES;
    self.titleField.hidden = YES;
    self.skipButton.hidden = YES;
    self.skipTestBtn.hidden = YES;
    //创建view
    [self setupUI];
    
    //跳过的时候，调用合成接口
    __weak typeof(self) weakSelf = self;
    
    [self.AVEngine mergeVideoWithVideoTitle:self.titleField.text SuccessBlock:^{
        
        if (!weakSelf.isSuccess && weakSelf.isAll) {
            NSDictionary *dict = @{@"playUrl":weakSelf.AVEngine.currentProductUrl};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CANPLAY" object:nil userInfo:dict];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (void)setupUI{
    //创建播放器层
    self.view.backgroundColor = RGB(0, 0, 0);
    self.playerItem = [AVPlayerItem playerItemWithURL:self.playUrl];
    NSLog(@"打印：%@", self.playUrl);
    if ((self.isSuccess && self.isAll) || (!self.isAll)) {
        [self addObserverToPlayItem:self.playerItem];
        NSLog(@"走了3");
    }
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.frame;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.view.layer addSublayer:self.playerLayer];
    
    isPlay = YES;
    
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
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66a" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.center = self.view.center;
    [self.view addSubview:self.playButton];
    //下一步
    if (self.isAll) {
        self.nextButton = [[UIButton alloc]initWithFrame:CGRectMake(SWitdh - 82, 0, 60, 60)];
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
    if ((self.isAll && self.isSuccess == NO) || self.isOnline) {
        
        self.waitIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.waitIndicator.frame = CGRectMake(0, 0, 65, 65);
        self.waitIndicator.center = self.view.center;
        [self.view addSubview:self.waitIndicator];
        
        [self.waitIndicator startAnimating];
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
    
    if (!self.isOnline && self.waitIndicator.isAnimating) {
        self.progress.hidden = YES;
        self.backButton.hidden = YES;
        self.playButton.hidden = YES;
    }
    if (self.isOnline && self.waitIndicator.isAnimating) {
        self.playButton.hidden = YES;
    }
    
    //手势
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls:)];
    [self.view addGestureRecognizer:singleTap];
}

- (void)onClickBack:(UIButton *)sender{
    
    if (!self.waitIndicator.isAnimating) {

        [MobClick event:@"BackView"];
        //返回
        if(self.DismissBlock){
            self.DismissBlock();
        }
        [self.navigationController popViewControllerAnimated:YES];
    }

}

- (void)onClickPlayOrPause:(UIButton *)sender {
    
    [MobClick event:@"PlayOrPause"];
    if(isPlay)
    {//之前是播放那就暂停 显示暂停图标
        
        [sender setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        [self.player pause];
    }else
    {//之前是暂停那就播放 显示播放图标
        [sender setImage:[UIImage imageWithIcon:@"\U0000e66a" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        [self.player play];
    }
    isPlay = !isPlay;
    [self scheduleHideControls];
}

- (void)onClickNext {
    
    DLYResource *resource = [[DLYResource alloc] init];
    [resource removeCurrentAllPart];
    //跳转下一步填写标题
    [self.player pause];
    isPlay = NO;
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    
    DLYExportViewController *exportVC = [[DLYExportViewController alloc] init];
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
#pragma mark - 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            NSLog(@"视频播放左转");
        }];
    }

}
- (void)deviceChangeAndHomeOnTheRight {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYPlayVideoViewController class]]) {
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            NSLog(@"视频播放右转");
        }];
    }
}

#pragma mark - 播放完成通知
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

//即将进入后台，暂停视频
- (void)applicationWillResignActive {
    
    [self.player pause];
    isPlay = NO;
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
}

- (void)playbackFinished:(NSNotification *)notification {

    [self.player pause];
    isPlay = NO;
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
//进度条监控
- (void)addProgressObserver {
    AVPlayerItem *playerItem = self.player.currentItem;
    //这里每秒执行一次
    __weak typeof(self) weakSelf = self;
    _progressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(playerItem.duration);
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
            if (!self.isOnline && self.waitIndicator.isAnimating) {
                [self.waitIndicator stopAnimating];
                self.backButton.hidden = NO;
                self.progress.hidden = NO;
                self.playButton.hidden = NO;
            }
            if (self.isOnline && self.waitIndicator.isAnimating) {
                [self.waitIndicator stopAnimating];
                self.playButton.hidden = NO;
            }
            if (self.isAll) {
                self.nextButton.hidden = NO;
            }
            [self.player play];
            isPlay = YES;
            [self scheduleHideControls];
        }else if (playerItem.status == AVPlayerItemStatusFailed){
            
            NSLog(@"Error fail : %@", playerItem.error);
            
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓存时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        NSLog(@"共缓存: %.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        //        [self.loadingView startAnimating];
        // 当缓冲是空的时候
        //        if (self.playerItem.playbackBufferEmpty) {
        //            NSLog(@"缓存为空");
        //            [self loadedTimeRanges];
        //        }
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        //        [self.loadingView stopAnimating];
        // 当缓冲好的时候
        //        if (self.playerItem.playbackLikelyToKeepUp && self.state == WMPlayerStateBuffering){
        //            NSLog(@"55555%s WMPlayerStatePlaying",__FUNCTION__);
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
    return YES;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)textFieldDidChange:(UITextField *)textField {
    int length = 8;//限制的字数
    NSString *toBeString = textField.text;
    NSString *lang = self.titleField.textInputMode.primaryLanguage; //键盘输入模式
    if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [textField markedTextRange];       //获取高亮部分
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position || !selectedRange)
        {
            if (toBeString.length > length)
            {
                NSRange rangeIndex = [toBeString rangeOfComposedCharacterSequenceAtIndex:length];
                if (rangeIndex.length == 1)
                {
                    textField.text = [toBeString substringToIndex:length];
                }
                else
                {
                    NSRange rangeRange = [toBeString rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, length)];
                    textField.text = [toBeString substringWithRange:rangeRange];
                }
            }
        }
        
    }
}
#pragma mark ==== 控件显隐

-(void)toggleControls:(UITapGestureRecognizer *)recognizer {
    //转菊花判断
    if (self.waitIndicator.isAnimating) {
        return;
    }else {
        if(self.progress.isHidden){
            [self showControlsFast];
        }else{
            [self hideControlsFast];
        }
        
        [self scheduleHideControls];
    }
}

//1快速显示
-(void)showControlsFast {
    
    self.playButton.alpha = 0.0;
    self.playButton.hidden = NO;
    
    if (self.nextButton) {
        self.nextButton.alpha = 0.0;
        self.nextButton.hidden = NO;
    }

    self.backButton.alpha = 0.0;
    self.backButton.hidden = NO;

    self.progress.alpha = 0.0;
    self.progress.hidden = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.playButton.alpha = 1.0;
        self.backButton.alpha = 1.0;
        self.progress.alpha = 1.0;
        if (self.nextButton) {
            self.nextButton.alpha = 1.0;
        }
    }];
    
}
//2快速隐藏
-(void)hideControlsFast {
    [self hideControlsWithDuration:0.2];
}
//3慢隐藏
-(void)hideControlsSlowly {
    [self hideControlsWithDuration:0.5];
}
//4隐藏操作
-(void)hideControlsWithDuration:(NSTimeInterval)duration {
    self.playButton.alpha = 1.0;
    self.backButton.alpha = 1.0;
    self.progress.alpha = 1.0;
    if (self.nextButton) {
        self.nextButton.alpha = 1.0;
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.playButton.alpha = 0.0;
        self.backButton.alpha = 0.0;
        self.progress.alpha = 0.0;
        if (self.nextButton) {
            self.nextButton.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        self.playButton.hidden = YES;
        self.backButton.hidden = YES;
        self.progress.hidden = YES;
        if (self.nextButton) {
            self.nextButton.hidden = YES;
        }
    }];
    
}
//5
-(void)scheduleHideControls {
    if(!self.progress.isHidden) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideControlsSlowly) withObject:nil afterDelay:3.0];
    }
}

#pragma mark - UI事件 播放和暂停

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    if (self.waitIndicator.isAnimating) {
        [self.waitIndicator stopAnimating];
    }
    
    [MobClick endLogPageView:@"PlayVideoView"];
    [self.player pause];
    isPlay = NO;
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:23 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CANPLAY" object:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.titleField.text forKey:@"videoTitle"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:self.progressObserver];
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
