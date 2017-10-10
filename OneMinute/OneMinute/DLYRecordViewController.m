//
//  DLYRecordViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYRecordViewController.h"
#import "DLYAnnularProgress.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DLYPlayVideoViewController.h"
#import "DLYMiniVlogTemplate.h"
#import "DLYResource.h"
#import "DLYAVEngine.h"
#import "DLYSession.h"
#import "DLYDownloadManager.h"
#include <libavformat/avformat.h>
#import "DLYMovieObject.h"
#import "DLYTitleView.h"
#import "DLYThemesData.h"

typedef void(^CompCompletedBlock)(BOOL success);
typedef void(^CompProgressBlcok)(CGFloat progress);

@interface DLYRecordViewController ()<DLYCaptureManagerDelegate,UIAlertViewDelegate,UIGestureRecognizerDelegate,YBPopupMenuDelegate,DLYIndicatorViewDelegate>
{
    NSInteger cursorTag;
    //记录选中的样片类型
    NSInteger selectType;
    //记录白色闪动条的透明度
    NSInteger prepareAlpha;
    //记录闪烁的tag
    NSInteger prepareTag;
    //记录上次闪烁的tag
    NSInteger oldPrepareTag;
    //选择的片段
    NSInteger selectPartTag;
    //将要更换最新片段
    NSInteger selectNewPartTag;
    double _shootTime;
    NSMutableArray * partModelArray; //模拟存放拍摄片段的模型数组
    NSMutableArray * typeModelArray; //模拟选择样式的模型数组
    BOOL isNeededToSave;
    BOOL isMicGranted;//麦克风权限是否被允许
    BOOL isFront;
    BOOL isSlomoCamera;
    CGFloat _initialPinchZoom;
    dispatch_source_t _timer;
}
@property (nonatomic,assign) CGFloat                            beginGestureScale;//记录开始的缩放比例
@property (nonatomic,assign) CGFloat                            effectiveScale;//最后的缩放比例
@property (nonatomic, copy) NSArray                             *btnImg;//场景对应的图片
@property (nonatomic, strong) DLYAVEngine                       *AVEngine;
@property (nonatomic, strong) UIView                            *previewView;
@property (nonatomic, strong) UIImageView                       *focusCursorImageView;
@property (nonatomic, strong) UIImageView                       *faceRegionImageView;
@property (nonatomic, strong) UIView * sceneView; //选择场景的view
@property (nonatomic, strong) UIView * shootView; //拍摄界面
@property (nonatomic, strong) UIView * timeView;
@property (nonatomic, strong) NSTimer *shootTimer;          //拍摄读秒计时器
@property (nonatomic, strong) NSTimer * prepareShootTimer; //准备拍摄片段闪烁的计时器
@property (nonatomic, strong) DLYAnnularProgress * progressView;    //环形进度条
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) DLYAlertView *alert;          //警告框
@property (nonatomic, strong) DLYTitleView *titleView;      //拍摄说明
@property (nonatomic, strong) UIButton *chooseScene;        //选择场景
@property (nonatomic, strong) UILabel *chooseSceneLabel;    //选择场景文字
@property (nonatomic, strong) UIButton *toggleCameraBtn;    //切换摄像头
@property (nonatomic, strong) UIButton *flashButton;        //闪光灯
@property (nonatomic, strong) UIView *backView;             //控制页面底层
@property (nonatomic, strong) UIButton *recordBtn;          //拍摄按钮
@property (nonatomic, strong) UIButton *nextButton;         //下一步按钮
@property (nonatomic, strong) UIButton *deleteButton;       //删除全部按钮
@property (nonatomic, strong) UIView *vedioEpisode;         //片段展示底部
@property (nonatomic, strong) UIScrollView *backScrollView; //片段展示滚图
@property (nonatomic, strong) UIView *playView;             //单个片段编辑页面
@property (nonatomic, strong) UIButton *playButton;         //播放单个视频
@property (nonatomic, strong) UIButton *deletePartButton;   //删除单个视频
@property (nonatomic, strong) UIButton *scenceDisapper;     //取消选择模板
@property (nonatomic, strong) UIImageView *warningIcon;     //拍摄指导
@property (nonatomic, strong) UILabel *shootGuide;          //拍摄指导
@property (nonatomic, strong) UIButton *cancelButton;       //取消拍摄
@property (nonatomic, strong) UIButton *completeButton;     //拍摄单个片段完成
@property (nonatomic, strong) UILabel *timeNumber;          //倒计时显示label
@property (nonatomic, strong) DLYResource  *resource;       //资源管理类
@property (nonatomic, strong) DLYSession *session;          //录制会话管理类
@property (nonatomic, strong) UILabel *chooseTitleLabel;    //选择场景说明
@property (nonatomic, strong) UIButton *seeRush;            //观看样片
@property (nonatomic, strong) UILabel *alertLabel;          //提示文字
@property (nonatomic, strong) UIButton *sureBtn;            //确定切换场景
@property (nonatomic, strong) UIButton *giveUpBtn;          //放弃切换场景
@property (nonatomic, strong) UIView *typeView;             //场景view
@property (nonatomic, strong) DLYPopupMenu *partBubble;     //删除单个气泡
@property (nonatomic, strong) DLYPopupMenu *allBubble;      //删除全部气泡
@property (nonatomic, strong) NSMutableArray *viewArr;      //视图数组
@property (nonatomic, strong) NSMutableArray *bubbleTitleArr;//视图数组
@property (nonatomic, assign) BOOL isAvalible;              //权限都已经许可

@end

@implementation DLYRecordViewController

- (DLYResource *)resource{
    if (!_resource) {
        _resource = [[DLYResource alloc] init];
    }
    return _resource;
}
- (UIImageView *)focusCursorImageView {
    if (_focusCursorImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focusIcon"]];
        imageView.frame = CGRectMake(0, 0, 50, 50);
        _focusCursorImageView = imageView;
        [self.view addSubview:_focusCursorImageView];
    }
    return _focusCursorImageView;
}
-(UIImageView *)faceRegionImageView{
    if (_faceRegionImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
        imageView.layer.cornerRadius = 10;
        imageView.layer.borderWidth = 2;
        imageView.layer.borderColor = [[UIColor colorWithHexString:@"#FFD700" withAlpha:0.6] CGColor];
        _faceRegionImageView = imageView;
        [self.view addSubview:_faceRegionImageView];
    }
    return _faceRegionImageView;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.AVEngine restartRecording];
    [MobClick beginLogPageView:@"RecordView"];
    
    self.isAppear = YES;
    NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    self.isAppear = NO;
    
    if (self.newState == 1) {
        [self deviceChangeAndHomeOnTheRightNewLayout];
    }else {
        [self deviceChangeAndHomeOnTheLeftNewLayout];
    }
    
    if (self.isExport) {
        
        [self initData];
        if (!self.deleteButton.isHidden && self.deleteButton) {
            if (self.allBubble) {
                [self.allBubble removeFromSuperview];
                self.allBubble = nil;
            }
            self.deleteButton.selected = NO;
            self.deleteButton.backgroundColor = RGBA(0, 0, 0, 0.4);
            self.deleteButton.hidden = YES;
        }
        if (!self.nextButton.isHidden && self.nextButton) {
            self.nextButton.hidden = YES;
        }
        if (self.recordBtn.isHidden && self.recordBtn) {
            self.recordBtn.hidden = NO;
        }
        if (!self.playView.isHidden && self.playView) {
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
            self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
            self.playView.hidden = YES;
        }
        [self createPartViewLayout];
        self.isExport = NO;
    }
    
    if (!self.isPlayer) {
        [self createPartViewLayout];
    }
    self.isPlayer = NO;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.AVEngine pauseRecording];
    [MobClick endLogPageView:@"RecordView"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isAvalible = [self monitorPermission];
    
    [DLYThemesData sharedInstance];
    
    av_register_all();
    [DLYIndicatorView sharedIndicatorView].delegate = self;
    self.isAppear = YES;
    NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    self.isAppear = NO;
    //    [self initData];
    NSInteger draftNum = [self initDataReadDraft];
    [self setupUI];
    [self initializationRecorder];
    
    //According to the preview center focus after launch
    CGPoint point = self.previewView.center;
    CGPoint cameraPoint = [self.AVEngine.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self.AVEngine focusWithMode:AVCaptureFocusModeAutoFocus atPoint:cameraPoint];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordViewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (draftNum == partModelArray.count) {
        self.recordBtn.hidden = YES;
        self.isSuccess = YES;
        if (self.newState == 1) {
            self.nextButton.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.nextButton.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.nextButton.hidden = NO;
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showNextButtonPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNextButtonPopup"];
            DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.nextButton titles:@[@"去合成视频"] icons:nil menuWidth:120 delegate:self];
            normalBubble.showMaskAlpha = 1;
        }
        if (self.newState == 1) {
            self.deleteButton.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.deleteButton.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.deleteButton.hidden = NO;
    }
}
#pragma mark ==== 气泡
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (self.isAvalible) {
        [self showCueBubble];
    }
}

- (void)showCueBubble {
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showFirstPopup"]){
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showFirstPopup"];
        NSArray *arr = @[self.chooseScene, self.flashButton, self.toggleCameraBtn, self.recordBtn];
        self.viewArr = [NSMutableArray arrayWithArray:arr];
        NSArray *titleArr = @[@"选择场景", @"闪光灯", @"切换摄像头", @"录制视频"];
        self.bubbleTitleArr = [NSMutableArray arrayWithArray:titleArr];
        [self showPopupMenu];
    }
}

- (void)showPopupMenu {
    
    if (self.viewArr.count == 0) {
        return;
    }
    UIButton *btn = self.viewArr[0];
    NSString *title = self.bubbleTitleArr[0];
    NSArray *titles = @[title];
    DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:btn titles:titles icons:nil menuWidth:120 delegate:self];
    normalBubble.showMaskAlpha = 1;
    [self.viewArr removeObjectAtIndex:0];
    [self.bubbleTitleArr removeObjectAtIndex:0];
}
//气泡消失的代理方法
- (void)ybPopupMenuDidDismiss {
    [self showPopupMenu];
}

#pragma mark - GestureRecognizer Delegate -

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}
#pragma mark - 捏合屏幕改变焦距
- (void)pinchGestureRecognizerAction:(UIPinchGestureRecognizer *)pin {
    if (pin.state == UIGestureRecognizerStateBegan) {
        
    } else if (pin.state == UIGestureRecognizerStateChanged) {
        CGFloat newValue;
        if (pin.scale > 1) {
            newValue = pin.scale/200;
            if (newValue > 3) newValue = 3;
        } else {
            newValue =  - (3.0 * (1 - pin.scale)) * 0.02;
            NSLog(@"pin.scale: %f, newValue:%f", pin.scale, newValue);
            if (newValue < 1) newValue = 1;
        }
        [self cameraBackgroundDidChangeZoom:newValue];
    } else if (pin.state == UIGestureRecognizerStateEnded) {
        
    }
}
#pragma mark - 数码变焦 1-3倍
- (void)cameraBackgroundDidChangeZoom:(CGFloat)zoom {
    AVCaptureDevice *captureDevice = self.AVEngine.videoDevice;
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        [captureDevice rampToVideoZoomFactor:zoom withRate:50];
    }else{
        
    }
}
//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.previewView];
        CGPoint convertedLocation = [self.AVEngine.captureVideoPreviewLayer convertPoint:location fromLayer:self.AVEngine.captureVideoPreviewLayer.superlayer];
        if ( ! [self.AVEngine.captureVideoPreviewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------- %f ------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        
        //        CGFloat maxScaleAndCropFactor = self.AVEngine.videoConnection.videoMaxScaleAndCropFactor;
        //        NSLog(@"预览最大倍率: %f",maxScaleAndCropFactor);
        
        //        if (self.effectiveScale > maxScaleAndCropFactor)
        //            self.effectiveScale = maxScaleAndCropFactor;
        //
        //        self.AVEngine.videoConnection.videoScaleAndCropFactor = self.effectiveScale;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.AVEngine.captureVideoPreviewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        self.AVEngine.effectiveScale = self.effectiveScale;
        
    }
}
- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser {
    // 1
    //    if (!self.AVEngine.videoDevice)
    //        return;
    
    // 2
    if (recogniser.state == UIGestureRecognizerStateBegan)
    {
        _initialPinchZoom = self.AVEngine.videoDevice.videoZoomFactor;
    }
    
    // 3
    NSError *error = nil;
    [self.AVEngine.videoDevice lockForConfiguration:&error];
    
    if (!error) {
        CGFloat zoomFactor;
        CGFloat scale = recogniser.scale;
        if (scale < 1.0f) {
            // 4
            zoomFactor = _initialPinchZoom - pow(self.AVEngine.videoDevice.activeFormat.videoMaxZoomFactor, 1.0f - recogniser.scale);
        }
        else
        {
            // 5
            zoomFactor = _initialPinchZoom + pow(self.AVEngine.videoDevice.activeFormat.videoMaxZoomFactor, (recogniser.scale - 1.0f) / 2.0f);
        }
        
        // 6
        zoomFactor = MIN(10.0f, zoomFactor);
        zoomFactor = MAX(1.0f, zoomFactor);
        
        // 7
        [self.AVEngine.videoDevice setVideoZoomFactor:zoomFactor];
        
        // 8
        [self.AVEngine.videoDevice unlockForConfiguration];
    }
}
#pragma mark ==== 初始化数据
- (NSInteger)initDataReadDraft {
    
    self.btnImg = @[@"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671",
                    @"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671",
                    @"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671"];
    
    BOOL isExitDraft = [self.session isExistDraftAtFile];
    NSMutableArray *draftArr = [NSMutableArray array];
    
    if (isExitDraft) {
        NSArray *arr = [self.resource loadDraftPartsFromDocument];
        
        for (NSURL *url in arr) {
            NSString *partPath = url.path;
            NSString *newPath = [partPath stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
            NSArray *arr = [newPath componentsSeparatedByString:@"part"];
            NSString *partNum = arr.lastObject;
            [draftArr addObject:partNum];
        }
    }
    ////////////////////////////////////////////////////////////
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    [self.session saveCurrentTemplateWithId:template.templateId];
    partModelArray = [NSMutableArray arrayWithArray:template.parts];
    for (int i = 0; i < partModelArray.count; i++) {
        DLYMiniVlogPart *part = partModelArray[i];
        if (i == 0) {
            part.prepareRecord = @"1";
        }else {
            part.prepareRecord = @"0";
        }
        part.recordStatus = @"0";
        part.duration = [self getDurationwithStartTime:part.starTime andStopTime:part.stopTime];
        part.partTime = [self getDurationwithStartTime:part.dubStartTime andStopTime:part.dubStopTime];

    }
    /////////////////////////////////
    if (isExitDraft) {
        for (NSString *str in draftArr) {
            NSInteger num = [str integerValue];
            DLYMiniVlogPart *part = partModelArray[num];
            part.recordStatus = @"1";
        }
        
        for (DLYMiniVlogPart *part1 in partModelArray) {
            part1.prepareRecord = @"0";
        }
        
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogPart *part2 = partModelArray[i];
            if([part2.recordStatus isEqualToString:@"0"])
            {
                part2.prepareRecord = @"1";
                break;
            }
        }
        
    }
    /////////////////////////////////
    typeModelArray = [[NSMutableArray alloc]init];
    //通用,美食,旅行,生活
    NSArray *typeNameArray = @[@"Primary.json",@"Secondary.json",@"Advanced.json",@"Gourmandism001.json",@"Traveler001.json",@"ColorLife001.json",@"Gourmandism002.json",@"Traveler002.json",@"ColorLife002.json",@"Gourmandism003.json",@"Traveler003.json",@"ColorLife003.json"];
    for(int i = 0; i < typeNameArray.count; i ++)
    {
        DLYMiniVlogTemplate *template = [self.session loadTemplateWithTemplateName:typeNameArray[i]];
        [typeModelArray addObject:template];
    }
    
    _shootTime = 0;
    cursorTag = 10001;
    self.isSuccess = NO;
    selectPartTag = 10001; //也不影响吧
    selectType = 0; //暂时先这么写
    NSString *typeName = template.templateId;
    for (int i = 0; i < typeModelArray.count; i ++) {
        DLYMiniVlogTemplate *templateModel = typeModelArray[i];
        if ([templateModel.templateId isEqualToString:typeName]) {
            selectType = i;
        }
    }
    
    if (isExitDraft) {
        return draftArr.count;
    }else{
        return 0;
    }
}
- (void)initData {
    
    self.btnImg = @[@"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671",
                    @"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671",
                    @"\U0000e665", @"\U0000e780", @"\U0000e6f1", @"\U0000e671"];
    
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    [self.session saveCurrentTemplateWithId:template.templateId];
    partModelArray = [NSMutableArray arrayWithArray:template.parts];
    
    for (int i = 0; i < partModelArray.count; i++) {
        DLYMiniVlogPart *part = partModelArray[i];
        if (i == 0) {
            part.prepareRecord = @"1";
        }else {
            part.prepareRecord = @"0";
        }
        part.recordStatus = @"0";
        part.duration = [self getDurationwithStartTime:part.starTime andStopTime:part.stopTime];
        part.partTime = [self getDurationwithStartTime:part.dubStartTime andStopTime:part.dubStopTime];
    }
    //contentSize更新
    float episodeHeight = (self.vedioEpisode.height - (partModelArray.count - 1) * 2) / partModelArray.count;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * partModelArray.count + (partModelArray.count - 1) * 2);
    
    //模板数据
    typeModelArray = [[NSMutableArray alloc]init];
    NSArray *typeNameArray = @[@"Primary.json",@"Secondary.json",@"Advanced.json",@"Gourmandism001.json",@"Traveler001.json",@"ColorLife001.json",@"Gourmandism002.json",@"Traveler002.json",@"ColorLife002.json",@"Gourmandism003.json",@"Traveler003.json",@"ColorLife003.json"];
    for(int i = 0; i < typeNameArray.count; i ++)
    {
        DLYMiniVlogTemplate *template = [self.session loadTemplateWithTemplateName:typeNameArray[i]];
        [typeModelArray addObject:template];
    }
    
    _shootTime = 0;
    selectPartTag = 10001;
    cursorTag = 10001;
    self.isSuccess = NO;
    
    selectType = 0; //暂时先这么写
    NSString *typeName = template.templateId;
    for (int i = 0; i < typeModelArray.count; i ++) {
        DLYMiniVlogTemplate *templateModel = typeModelArray[i];
        if ([templateModel.templateId isEqualToString:typeName]) {
            selectType = i;
        }
    }
}

- (NSString *)getDurationwithStartTime:(NSString *)startTime andStopTime:(NSString *)stopTime {
    
    int startDuration = 0;
    int stopDuation = 0;
    NSArray *startArr = [startTime componentsSeparatedByString:@":"];
    for (int i = 0; i < 3; i ++) {
        NSString *timeStr = startArr[i];
        int time = [timeStr intValue];
        if (i == 0) {
            startDuration = startDuration + time * 60 * 1000;
        }if (i == 1) {
            startDuration = startDuration + time * 1000;
        }else {
            startDuration = startDuration + time;
        }
    }
    
    NSArray *stopArr = [stopTime componentsSeparatedByString:@":"];
    for (int i = 0; i < 3; i ++) {
        NSString *timeStr = stopArr[i];
        int time = [timeStr intValue];
        if (i == 0) {
            stopDuation = stopDuation + time * 60 * 1000;
        }if (i == 1) {
            stopDuation = stopDuation + time * 1000;
        }else {
            stopDuation = stopDuation + time;
        }
    }
    
    float duration = (stopDuation - startDuration) * 0.001;
    NSString *duraStr = [NSString stringWithFormat:@"%.3f", duration];
    return duraStr;
}

#pragma mark ==== 主界面
- (void)setupUI {
    self.view.backgroundColor = RGB(0, 0, 0);
    //PreviewView
    self.previewView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.previewView.backgroundColor = [UIColor clearColor];
    
    [self.view insertSubview:self.previewView atIndex:0];
    
    //创建手势
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerAction:)];
    pinchGestureRecognizer.delegate = self;
    [self.previewView addGestureRecognizer:pinchGestureRecognizer];
    
    //通用button 选择场景button
    self.chooseScene = [[UIButton alloc]initWithFrame:CGRectMake(11, 16, 40, 40)];
    self.chooseScene.backgroundColor = RGBA(0, 0, 0, 0.4);
    //    [self.chooseScene setImage:[UIImage imageWithIcon:@"\U0000e665" inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.chooseScene addTarget:self action:@selector(onClickChooseScene:) forControlEvents:UIControlEventTouchUpInside];
    self.chooseScene.layer.cornerRadius = 20;
    self.chooseScene.clipsToBounds = YES;
    self.chooseScene.titleLabel.font = FONT_SYSTEM(14);
    [self.chooseScene setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    [self.view addSubview:self.chooseScene];
    //显示场景的label
    self.chooseSceneLabel = [[UILabel alloc]initWithFrame:CGRectMake(11, self.chooseScene.bottom + 2, 40, 13)];
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    self.chooseSceneLabel.text = template.templateTitle;
    self.chooseSceneLabel.font = FONT_SYSTEM(12);
    self.chooseSceneLabel.textColor = RGBA(255, 255, 255, 1);
    self.chooseSceneLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.chooseSceneLabel];
    
    NSArray *typeNameArray = @[@"Primary.json",@"Secondary.json",@"Advanced.json",@"Gourmandism001.json",@"Traveler001.json",@"ColorLife001.json",@"Gourmandism002.json",@"Traveler002.json",@"ColorLife002.json",@"Gourmandism003.json",@"Traveler003.json",@"ColorLife003.json"];
    for (int i = 0; i < typeNameArray.count; i ++) {
        if ([template.templateId isEqualToString:typeNameArray[i]]) {
            [self.chooseScene setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        }
    }
    
    //闪光
    self.flashButton = [[UIButton alloc]initWithFrame:CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40)];
    self.flashButton.layer.cornerRadius = 20;
    self.flashButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.flashButton.clipsToBounds = YES;
    [self.flashButton setImage:[UIImage imageWithIcon:@"\U0000e600" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.flashButton addTarget:self action:@selector(onClickFlashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    //切换前置摄像头
    self.toggleCameraBtn = [[UIButton alloc]initWithFrame:CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40)];
    self.toggleCameraBtn.layer.cornerRadius = 20;
    self.toggleCameraBtn.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.toggleCameraBtn.clipsToBounds = YES;
    [self.toggleCameraBtn setImage:[UIImage imageWithIcon:@"\U0000e668" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.toggleCameraBtn addTarget:self action:@selector(toggleCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleCameraBtn];
    
    //右边的view
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT)];
    self.backView.backgroundColor = RGBA(0, 0, 0, 0.7);
    [self.view addSubview:self.backView];
    
    //拍摄按钮
    self.recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(43 * SCALE_WIDTH, 0, 60*SCALE_WIDTH, 60 * SCALE_WIDTH)];
    self.recordBtn.centerY = self.backView.centerY;
    [self.recordBtn setImage:[UIImage imageWithIcon:@"\U0000e664" inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.recordBtn.backgroundColor = RGB(255, 0, 0);
    self.recordBtn.layer.cornerRadius = 30 * SCALE_WIDTH;
    self.recordBtn.clipsToBounds = YES;
    [self.recordBtn addTarget:self action:@selector(startRecordBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:self.recordBtn];
    
    //跳转成片播放界面
    self.nextButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.nextButton.backgroundColor = RGB(255, 0, 0);
    self.nextButton.center = self.view.center;
    self.nextButton.layer.cornerRadius = 30;
    self.nextButton.clipsToBounds = YES;
    self.nextButton.hidden = YES;
    [self.nextButton setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
    self.nextButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    [self.nextButton addTarget:self action:@selector(onClickNextStep:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    //删除全部片段
    self.deleteButton = [[UIButton alloc]initWithFrame:CGRectMake(self.nextButton.left - 91, self.nextButton.top, 60, 60)];
    self.deleteButton.layer.cornerRadius = 30;
    self.deleteButton.clipsToBounds = YES;
    self.deleteButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.deleteButton.hidden = YES;
    [self.deleteButton setImage:[UIImage imageWithIcon:@"\U0000e669" inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(onClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteButton];
    
    //片段view
    self.vedioEpisode = [[UIView alloc]initWithFrame:CGRectMake(self.recordBtn.right, 15 * SCALE_HEIGHT, 53, SCREEN_HEIGHT - 30  * SCALE_HEIGHT)];
    [self.backView addSubview:self.vedioEpisode];
    self.backScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, 53, self.vedioEpisode.height)];
    self.backScrollView.showsVerticalScrollIndicator = NO;
    self.backScrollView.showsHorizontalScrollIndicator = NO;
    self.backScrollView.bounces = NO;
    [self.vedioEpisode addSubview:self.backScrollView];
    float episodeHeight = (self.vedioEpisode.height - (partModelArray.count - 1) * 2) / partModelArray.count;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * partModelArray.count + (partModelArray.count - 1) * 2);
    _prepareShootTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(prepareShootAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_prepareShootTimer forMode:NSRunLoopCommonModes];
    [_prepareShootTimer setFireDate:[NSDate distantFuture]];
    
    //右侧编辑页面
    self.playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.recordBtn.x + self.recordBtn.width, SCREEN_HEIGHT)];
    self.playView.hidden = YES;
    [self.backView addSubview:self.playView];
    //右侧：播放某个片段的button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60 * SCALE_WIDTH, (SCREEN_HEIGHT - 152)/2, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.playButton addTarget:self action:@selector(onClickPlayPartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:15 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.playButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.playButton.layer.borderWidth = 1;
    [self.playView addSubview:self.playButton];
    //右侧：删除某个片段的button
    self.deletePartButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60* SCALE_WIDTH, self.playButton.bottom + 32, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.deletePartButton addTarget:self action:@selector(onClickDeletePartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.deletePartButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.deletePartButton.layer.borderWidth = 1;
    [self.playView addSubview:self.deletePartButton];
    
    //创建片段界面
    [self createPartView];
    //创建场景页面
    [self createSceneView];
    [self.view addSubview:[self shootView]];
}
//添加捏合事件

//- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser
//{
//    // 1
//    if (!self.AVEngine.videoDevice)
//    {
//        return;
//    }
//
//    // 2
//    if (recogniser.state == UIGestureRecognizerStateBegan)
//    {
//        _initialPinchZoom = self.AVEngine.videoDevice.videoZoomFactor;
//    }
//
//    // 3
//    NSError *error = nil;
//    [self.AVEngine.videoDevice lockForConfiguration:&error];
//
//    if (!error) {
//        CGFloat zoomFactor;
//        CGFloat scale = recogniser.scale;
//        if (scale < 1.0f) {
//            // 4
//            zoomFactor = _initialPinchZoom - pow(self.AVEngine.videoDevice.activeFormat.videoMaxZoomFactor, 1.0f - recogniser.scale);
//        }
//        else
//        {
//            // 5
//            zoomFactor = _initialPinchZoom + pow(self.AVEngine.videoDevice.activeFormat.videoMaxZoomFactor, (recogniser.scale - 1.0f) / 2.0f);
//        }
//
//        // 6
//        zoomFactor = MIN(10.0f, zoomFactor);
//        zoomFactor = MAX(1.0f, zoomFactor);
//
//        // 7
//        self.AVEngine.videoDevice.videoZoomFactor = zoomFactor;
//
//        // 8
//        [self.AVEngine.videoDevice unlockForConfiguration];
//    }
//}
#pragma mark - 初始化相机
- (void)initializationRecorder {
    
    self.AVEngine = [[DLYAVEngine alloc] initWithPreviewView:self.previewView];
    self.AVEngine.delegate = self;
}

#pragma mark -触屏自动调整曝光-
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    if (touch.view != self.backView && touch.view != self.sceneView && touch.view != self.playView)
    {
        CGPoint point = [touch locationInView:self.previewView];
        CGPoint cameraPoint = [self.AVEngine.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
        [self.AVEngine focusWithMode:AVCaptureFocusModeAutoFocus atPoint:cameraPoint];
        [self setFocusCursorWithPoint:point];
    }
}
- (void)setFocusCursorWithPoint:(CGPoint)point {
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.6, 1.6);
    self.focusCursorImageView.alpha = 1.0;
    [UIView animateWithDuration:0.5 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:2.0 animations:^{
            self.focusCursorImageView.alpha = 0.3;
        } completion:^(BOOL finished) {
            self.focusCursorImageView.alpha = 0;
        }];
    }];
}

#pragma mark - AVCaptureManagerDelegate

-(void)displayRefrenceRect:(CGRect)faceRegion{
    
//    CGPoint origin = faceRegion.origin;
    CGSize size = faceRegion.size;
    
    if (size.width != 0 && size.height != 0) {
        self.faceRegionImageView.hidden = NO;
        self.faceRegionImageView.frame = faceRegion;
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            self.faceRegionImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.faceRegionImageView.hidden = YES;
            self.faceRegionImageView.alpha = 1.0;
        }];
        
    }
}

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    if (!isNeededToSave) {
        return;
    }
    
    [self saveRecordedFileByUrl:outputFileURL];
}

/**
 延时拍摄抽取image
 
 @param assetUrl 延时拍摄模式生成的图片
 @param intervalTime keyFrame间隔时间
 @return 返回image
 */
-(UIImage*)getKeyImage:(NSURL *)assetUrl intervalTime:(NSInteger)intervalTime{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:assetUrl options:nil];
    NSParameterAssert(asset);
    if (!asset) {
        return nil;
    }
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    for (AVAssetTrack *track in videoTracks) {
        if (track.naturalSize.width > 0 && track.naturalSize.height > 0) {
            assetImageGenerator.maximumSize = CGSizeMake(track.naturalSize.width, track.naturalSize.height);
        }else{
            assetImageGenerator.maximumSize = CGSizeMake(480, 853);
        }
    }
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(intervalTime, 2) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    return thumbnailImage;
}

//image转pixelBuffer
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,frameWidth,frameHeight,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8,CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0,frameWidth,frameHeight),  image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

/**
 重新组帧延时视频
 
 @param videoUrl 正常录制的视频
 @param frameImgs 抽取的图片组
 @param fps 设置播放帧率
 @param progressImageBlock 合成进度
 @param completedBlock 完成回调
 */
- (void)composesVideoUrl:(NSURL *)videoUrl
               frameImgs:(NSArray<UIImage *> *)frameImgs
                     fps:(int32_t)fps
      progressImageBlock:(CompProgressBlcok)progressImageBlock
          completedBlock:(CompCompletedBlock)completedBlock {
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:videoUrl
                                                           fileType:AVFileTypeMPEG4
                                                              error:nil];
    NSParameterAssert(videoWriter);
    
    //获取原视频尺寸
    UIImage *image = frameImgs.firstObject;
    CGFloat frameWidth = CGImageGetWidth(image.CGImage);
    CGFloat frameHeight = CGImageGetHeight(image.CGImage);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameWidth], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameHeight], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput]) {
        [videoWriter addInput:writerInput];
    }
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", DISPATCH_QUEUE_SERIAL);
    __block int frame = -1;
    NSInteger count = frameImgs.count;
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([writerInput isReadyForMoreMediaData]) {
            if(++frame >= count) {
                [writerInput markAsFinished];
                [videoWriter finishWriting];
                NSLog(@"comp completed !");
                if (completedBlock) {
                    completedBlock(YES);
                }
                break;
            }
            
            CVPixelBufferRef buffer = NULL;
            UIImage *currentFrameImg = frameImgs[frame];
            buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:[currentFrameImg CGImage]];
            if (progressImageBlock) {
                CGFloat progress = frame * 1.0 / count;
                progressImageBlock(progress);
            }
            if (buffer) {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, fps)]) {
                    NSLog(@"FAIL");
                    if (completedBlock) {
                        completedBlock(NO);
                    }
                } else {
                    CFRelease(buffer);
                }
            }
        }
    }];
}
- (void)saveRecordedFileByUrl:(NSURL *)recordedFileUrl {
    
    DLYLog(@"Saving...");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        DLYLog(@"Saved!");
    });
}
#pragma mark ==== 左手模式重新布局
//设备方向改变后调用的方法
//后面改变的状态
- (void)deviceChangeAndHomeOnTheLeft {//左手模式
    
    if (![self.AVEngine isRecording]) {
        
        [self.AVEngine.captureSession beginConfiguration];
        
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        
        [self.AVEngine.captureSession commitConfiguration];
        
    }else{
        DLYLog(@"⚠️⚠️⚠️录制过程中不再重设录制正方向");
    }
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        [self deviceChangeAndHomeOnTheLeftNewLayout];
        DLYLog(@"首页左转");
    }
}
//home在右 初始状态
- (void)deviceChangeAndHomeOnTheRight {//右手模式
    
    if (![self.AVEngine isRecording]) {
        
        [self.AVEngine.captureSession beginConfiguration];
        
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
        [self.AVEngine.captureSession commitConfiguration];
        
    }else{
        DLYLog(@"⚠️⚠️⚠️录制过程中不再重设录制正方向");
    }
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        [self deviceChangeAndHomeOnTheRightNewLayout];
        DLYLog(@"首页右转");
    }
}

- (void)deviceChangeAndHomeOnTheLeftNewLayout {
    [self createLeftPartView];
    
    if (!self.playView.isHidden && self.playView) {
        UIButton *button = (UIButton *)[self.view viewWithTag:cursorTag];
        selectPartTag = cursorTag;
        //点击哪个item，光标移动到当前item
        prepareTag = button.tag;
        
        for (DLYMiniVlogPart *part in partModelArray) {
            if ([part.prepareRecord isEqualToString:@"1"]) {
                NSInteger i = [partModelArray indexOfObject:part];
                UIView *view = (UIView *)[self.view viewWithTag:30001 + i];
                [view removeFromSuperview];
            }
        }
    }
    
    [self changeDirectionOfView:M_PI];
}
- (void)deviceChangeAndHomeOnTheRightNewLayout{
    [self createPartView];
    
    if (!self.playView.isHidden) {
        UIButton *button = (UIButton *)[self.view viewWithTag:cursorTag];
        selectPartTag = cursorTag;
        //点击哪个item，光标移动到当前item
        prepareTag = button.tag;
        
        for (DLYMiniVlogPart *part in partModelArray) {
            if ([part.prepareRecord isEqualToString:@"1"]) {
                NSInteger i = [partModelArray indexOfObject:part];
                UIView *view = (UIView *)[self.view viewWithTag:30001 + i];
                [view removeFromSuperview];
            }
        }
    }
    [self changeDirectionOfView:0];
}
- (void)changeDirectionOfView:(CGFloat)num {
    
    if (!self.warningIcon.isHidden && self.warningIcon) {
        if (num == 0) {
            self.warningIcon.frame = CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32);
        }else {
            self.warningIcon.frame = CGRectMake(28, 22, 32, 32);
        }
        self.warningIcon.transform = CGAffineTransformMakeRotation(num);
    }
    if (!self.shootGuide.isHidden && self.shootGuide) {
        if (num == 0) {
            self.shootGuide.frame = CGRectMake(0, SCREEN_HEIGHT - 49, 270, 30);
        }else {
            self.shootGuide.frame = CGRectMake(0, 19, 270, 30);
        }
        self.shootGuide.centerX = _shootView.centerX;
        self.shootGuide.transform = CGAffineTransformMakeRotation(num);
    }
    if (!self.titleView.isHidden && self.titleView) {
        if (num == 0) {
            self.titleView.frame = CGRectMake(SCREEN_WIDTH - 190, 20, 180, 30);
        }else {
            self.titleView.frame = CGRectMake(SCREEN_WIDTH - 190, SCREEN_HEIGHT - 50, 180, 30);
        }
        self.titleView.transform = CGAffineTransformMakeRotation(num);
    }
    
    if (!self.progressView.isHidden && self.progressView) {
        [UIView animateWithDuration:0.5f animations:^{
            self.progressView.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.timeNumber.isHidden && self.timeNumber) {
        [UIView animateWithDuration:0.5f animations:^{
            self.timeNumber.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.completeButton.isHidden && self.completeButton) {
        [UIView animateWithDuration:0.5f animations:^{
            self.completeButton.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.chooseScene.isHidden && self.chooseScene) {
        if (num == 0) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
        }else {
            self.chooseScene.frame = CGRectMake(11, SCREEN_HEIGHT - 56, 40, 40);
        }
        [UIView animateWithDuration:0.5f animations:^{
            self.chooseScene.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.chooseSceneLabel.isHidden && self.chooseSceneLabel) {
        if (num == 0) {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.bottom + 2, 40, 13);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.top - 15, 40, 13);
        }
        [UIView animateWithDuration:0.5f animations:^{
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.toggleCameraBtn.isHidden && self.toggleCameraBtn) {
        if (num == 0) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(11, 11, 40, 40);
        }
        [UIView animateWithDuration:0.5f animations:^{
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.flashButton.isHidden && self.flashButton) {
        if (num == 0) {
            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
        }else {
            self.flashButton.frame = CGRectMake(11, 61, 40, 40);
        }
        [UIView animateWithDuration:0.5f animations:^{
            self.flashButton.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    
    if (!self.playView.isHidden && self.playView) {
        [UIView animateWithDuration:0.5f animations:^{
            self.playButton.transform = CGAffineTransformMakeRotation(num);
            self.deletePartButton.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    
    if (!self.deleteButton.isHidden && self.deleteButton) {
        [UIView animateWithDuration:0.5f animations:^{
            self.deleteButton.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.nextButton.isHidden && self.nextButton) {
        [UIView animateWithDuration:0.5f animations:^{
            self.nextButton.transform = CGAffineTransformMakeRotation(num);
        }];
    }
    if (!self.cancelButton.isHidden && self.cancelButton) {
        if (num == 0) {
            self.cancelButton.frame = CGRectMake(0, _timeView.bottom + 40, 44, 44);
        }else {
            self.cancelButton.frame = CGRectMake(0, _timeView.top - 84, 44, 44);
        }
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(num);
    }
    
    if (!self.sceneView.isHidden) {
        
        if (!self.scenceDisapper.isHidden && self.scenceDisapper) {
            if (num == 0) {
                self.scenceDisapper.frame = CGRectMake(20, 20, 14, 14);
            }else {
                self.scenceDisapper.frame = CGRectMake(20, SCREEN_HEIGHT - 34, 14, 14);
            }
            [UIView animateWithDuration:0.5f animations:^{
                self.scenceDisapper.transform = CGAffineTransformMakeRotation(num);
            }];
        }
        if (!self.chooseTitleLabel.isHidden && self.chooseTitleLabel) {
            if (num == 0) {
                self.chooseTitleLabel.frame = CGRectMake(0, 19, 130, 20);
                self.chooseTitleLabel.centerX = self.sceneView.centerX;
            }else {
                self.chooseTitleLabel.frame = CGRectMake(0, SCREEN_HEIGHT - 39, 130, 20);
                self.chooseTitleLabel.centerX = self.sceneView.centerX;
            }
            [UIView animateWithDuration:0.5f animations:^{
                self.chooseTitleLabel.transform = CGAffineTransformMakeRotation(num);
            }];
        }
        if (!self.seeRush.isHidden && self.seeRush) {
            if (num == 0) {
                self.seeRush.frame = CGRectMake(SCREEN_WIDTH - 70, 21, 50, 17);
            }else {
                self.seeRush.frame = CGRectMake(SCREEN_WIDTH - 70, SCREEN_HEIGHT - 38, 50, 17);
            }
            [UIView animateWithDuration:0.5f animations:^{
                self.seeRush.transform = CGAffineTransformMakeRotation(num);
            }];
        }
        if (!self.alertLabel.isHidden && self.alertLabel) {
            if (num == 0) {
                self.alertLabel.frame = CGRectMake(0, 210, 368, 22);
                self.alertLabel.centerX = self.sceneView.centerX;
                self.sureBtn.frame = CGRectMake(0, self.alertLabel.bottom + 20, 61, 61);
                self.sureBtn.centerX = self.sceneView.centerX - 46;
                self.giveUpBtn.frame = CGRectMake(0, self.alertLabel.bottom + 20, 61, 61);
                self.giveUpBtn.centerX = self.sceneView.centerX  + 46;
            }else {
                self.alertLabel.frame = CGRectMake(0, SCREEN_HEIGHT - 232, 368, 22);
                self.alertLabel.centerX = self.sceneView.centerX;
                self.sureBtn.frame = CGRectMake(0, self.alertLabel.top - 81, 61, 61);
                self.sureBtn.centerX = self.sceneView.centerX + 46;
                self.giveUpBtn.frame = CGRectMake(0, self.alertLabel.top - 81, 61, 61);
                self.giveUpBtn.centerX = self.sceneView.centerX - 46;
            }
            [UIView animateWithDuration:0.5f animations:^{
                self.alertLabel.transform = CGAffineTransformMakeRotation(num);
                self.sureBtn.transform = CGAffineTransformMakeRotation(num);
                self.giveUpBtn.transform = CGAffineTransformMakeRotation(num);
            }];
        }
        for(int i = 0; i < typeModelArray.count; i++)
        {
            UIView *view = (UIView *)[self.view viewWithTag:101 + i];
            [UIView animateWithDuration:0.5f animations:^{
                view.transform = CGAffineTransformMakeRotation(num);
            }];
        }
    }
    
    if (!self.alert.isHidden && self.alert) {
        [UIView animateWithDuration:0.5f animations:^{
            self.alert.transform = CGAffineTransformMakeRotation(num);
        }];
    }
}

#pragma mark ==== button点击事件
//补光灯开关
- (void)onClickFlashAction {
    
    self.flashButton.selected = !self.flashButton.selected;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    if (self.flashButton.selected == YES) { //打开闪光灯
        [self.flashButton setImage:[UIImage imageWithIcon:@"\U0000e601" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        if ([device hasTorch]) {
            [device lockForConfiguration:&error];
            [device setTorchMode:AVCaptureTorchModeOn];
            [device unlockForConfiguration];
        }
    }else{//关闭闪光灯
        [self.flashButton setImage:[UIImage imageWithIcon:@"\U0000e600" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        if ([device hasTorch]) {
            [device lockForConfiguration:&error];
            [device setTorchMode:AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
}
#pragma mark ==== 切换摄像头
- (void)toggleCameraAction {
    
    [MobClick event:@"toggleCamera"];
    if (isSlomoCamera) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showSlomoCameraPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSlomoCameraPopup"];
            DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.toggleCameraBtn titles:@[@"慢镜头不能摄像头"] icons:nil menuWidth:120 delegate:self];
            normalBubble.showMaskAlpha = 1;
        }
        return;
    }
    self.toggleCameraBtn.selected = !self.toggleCameraBtn.selected;
    if (self.toggleCameraBtn.selected) {
        [self.AVEngine changeCameraInputDeviceisFront:YES];
        self.flashButton.hidden = YES;
        if (self.flashButton.selected) {
            self.flashButton.selected = NO;
        }
        isFront = YES;
    }else{
        [self.AVEngine changeCameraInputDeviceisFront:NO];
        if (self.newState == 1) {
            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
            self.flashButton.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.flashButton.frame = CGRectMake(11, 61, 40, 40);
            self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.flashButton.hidden = NO;
        isFront = NO;
    }
}
//选择场景
- (void)onClickChooseScene:(UIButton *)sender {
    
    [MobClick event:@"ChooseScene"];
    [self showChooseSceneView];
}
//显示模板页面
- (void)showChooseSceneView {
    
    [UIView animateWithDuration:0.1f animations:^{
        self.chooseScene.hidden = YES;
        self.toggleCameraBtn.hidden = YES;
        self.flashButton.hidden = YES;
        self.chooseSceneLabel.hidden = YES;
        self.backView.hidden = YES;
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
        if (self.newState == 1) {
            self.scenceDisapper.frame = CGRectMake(20, 20, 14, 14);
            self.scenceDisapper.transform = CGAffineTransformMakeRotation(0);
            self.chooseTitleLabel.frame = CGRectMake(0, 19, 130, 20);
            self.chooseTitleLabel.centerX = self.sceneView.centerX;
            self.chooseTitleLabel.transform = CGAffineTransformMakeRotation(0);
            self.seeRush.frame = CGRectMake(SCREEN_WIDTH - 70, 21, 50, 17);
            self.seeRush.transform = CGAffineTransformMakeRotation(0);
            for(int i = 0; i < typeModelArray.count; i++)
            {
                UIView *view = (UIView *)[self.view viewWithTag:101 + i];
                view.transform = CGAffineTransformMakeRotation(0);
            }
        }else {
            self.scenceDisapper.frame = CGRectMake(20, SCREEN_HEIGHT - 34, 14, 14);
            self.scenceDisapper.transform = CGAffineTransformMakeRotation(M_PI);
            self.chooseTitleLabel.frame = CGRectMake(0, SCREEN_HEIGHT - 39, 130, 20);
            self.chooseTitleLabel.centerX = self.sceneView.centerX;
            self.chooseTitleLabel.transform = CGAffineTransformMakeRotation(M_PI);
            self.seeRush.frame = CGRectMake(SCREEN_WIDTH - 70, SCREEN_HEIGHT - 38, 50, 17);
            self.seeRush.transform = CGAffineTransformMakeRotation(M_PI);
            for(int i = 0; i < typeModelArray.count; i++)
            {
                UIView *view = (UIView *)[self.view viewWithTag:101 + i];
                view.transform = CGAffineTransformMakeRotation(M_PI);
            }
        }
    } completion:^(BOOL finished) {
        self.sceneView.hidden = NO;
        self.sceneView.alpha = 1;
        //气泡
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showSeeRushPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSeeRushPopup"];
            DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.seeRush titles:@[@"观看样片"] icons:nil menuWidth:120 delegate:self];
            normalBubble.showMaskAlpha = 1;
        }
    }];
    
}
//拍摄视频按键
- (void)startRecordBtnAction {
    
    [MobClick event:@"StartRecord"];
    // REC START
    if (!self.AVEngine.isRecording) {
        
        NSInteger i = selectPartTag - 10000;
        DLYMiniVlogPart *part = partModelArray[i-1];
        [self.AVEngine startRecordingWithPart:part];
        // change UI
        [self.shootView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _shootTime = 0;
        [self createShootView];
        for (DLYMiniVlogPart *part in partModelArray) {
            if([part.prepareRecord isEqualToString:@"1"])
            {
                if(part.recordType != DLYMiniVlogRecordTypeNormal)
                {
                    if (self.newState == 1) {
                        self.warningIcon.frame = CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32);
                        self.warningIcon.transform = CGAffineTransformMakeRotation(0);
                    }else {
                        self.warningIcon.frame = CGRectMake(28, 22, 32, 32);
                        self.warningIcon.transform = CGAffineTransformMakeRotation(M_PI);
                    }
                    self.warningIcon.hidden = NO;
                    if (part.recordType == DLYMiniVlogRecordTypeSlomo) {
                        self.shootGuide.text = @"慢动作拍摄不能录制现场声音";
                    }else {
                        self.shootGuide.text = @"快镜头拍摄不能录制现场声音";
                    }
                }else
                {
                    self.warningIcon.hidden = YES;
                    self.shootGuide.text = @"拍摄指导：请保持光线充足";
                }
            }
        }
        
        [UIView animateWithDuration:0.5f animations:^{
            self.chooseScene.hidden = YES;
            self.chooseSceneLabel.hidden = YES;
            self.toggleCameraBtn.hidden = YES;
            self.flashButton.hidden = YES;
            self.backView.transform = CGAffineTransformMakeTranslation(self.backView.width, 0);
        } completion:^(BOOL finished) {
            self.backView.hidden = YES;
            self.shootView.hidden = NO;
            self.shootView.alpha = 1;
        }];
    }
}
//跳转至下一个界面按键
- (void)onClickNextStep:(UIButton *)sender {
    [MobClick event:@"NextStep"];
    DLYPlayVideoViewController * fvc = [[DLYPlayVideoViewController alloc]init];
    fvc.playUrl = self.AVEngine.currentProductUrl;
    fvc.isAll = YES;
    fvc.isSuccess = NO;
    fvc.beforeState = self.newState;
    self.isPlayer = YES;
    [self hideBubbleWhenPush];
    [self.navigationController pushViewController:fvc animated:YES];
}
//删除全部视频
- (void)onClickDelete:(UIButton *)sender {
    [MobClick event:@"DeleteAll"];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"deleteAllPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deleteAllPopup"];
        self.allBubble = [DLYPopupMenu showRelyOnView:sender titles:@[@"点击删除全部片段"] icons:nil menuWidth:120 delegate:self];
        self.allBubble.showMaskAlpha = 0;
        self.allBubble.dismissOnTouchOutside = NO;
        self.allBubble.dismissOnSelected = NO;
    }
    if (sender.selected == NO) {
        self.deleteButton.backgroundColor = RGBA(255, 0, 0, 1);
    }else {
        if (self.allBubble) {
            [self.allBubble removeFromSuperview];
            self.allBubble = nil;
        }
        sender.backgroundColor = RGBA(0, 0, 0, 0.4);
        [self.resource removeCurrentAllPartFromCache];
        [self.resource removeCurrentAllPartFromDocument];
        //数组初始化，view布局
        if (!self.playView.isHidden && self.playView) {
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
            self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
            self.playView.hidden = YES;
        }
        if (self.recordBtn.isHidden && self.recordBtn) {
            self.recordBtn.hidden = NO;
        }
        self.nextButton.hidden = YES;
        self.deleteButton.hidden = YES;
        [self initData];
        [self createPartViewLayout];
        self.isSuccess = NO;
    }
    sender.selected = !sender.selected;
    
}
//播放某个片段
- (void)onClickPlayPartVideo:(UIButton *)sender{
    [MobClick event:@"PlayPart"];
    NSInteger partNum = selectPartTag - 10000 - 1;
    DLYPlayVideoViewController *playVC = [[DLYPlayVideoViewController alloc] init];
    playVC.playUrl = [self.resource getPartUrlWithPartNum:partNum];
    playVC.isAll = NO;
    playVC.beforeState = self.newState;
    self.isPlayer = YES;
    [self hideBubbleWhenPush];
    [self.navigationController pushViewController:playVC animated:YES];
    
}
//删除某个片段
- (void)onClickDeletePartVideo:(UIButton *)sender {
    [MobClick event:@"DeletePart"];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"deletePartPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deletePartPopup"];
        self.partBubble = [DLYPopupMenu showRelyOnView:sender titles:@[@"点击删除该片段"] icons:nil menuWidth:120 delegate:self];
        self.partBubble.showMaskAlpha = 0;
        self.partBubble.dismissOnTouchOutside = NO;
        self.partBubble.dismissOnSelected = NO;
        
    }
    if (sender.selected == NO) {
        [sender setImage:[UIImage imageWithIcon:@"\U0000e669" inFont:ICONFONT size:24 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
        sender.layer.borderColor = RGBA(255, 0, 0, 1).CGColor;
    }else {
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
        [sender setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        sender.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        NSInteger partNum = selectPartTag - 10000 - 1;
        [self.resource removePartWithPartNumFormCache:partNum];
        [self.resource removePartWithPartNumFromDocument:partNum];
        [self deleteSelectPartVideo];
    }
    sender.selected = !sender.selected;
}

- (void)hideBubbleWhenPush {

    if (self.partBubble) {
        [self.partBubble removeFromSuperview];
        self.partBubble = nil;
    }
    if (self.allBubble) {
        [self.allBubble removeFromSuperview];
        self.allBubble = nil;
    }
}

//取消选择场景
- (void)onClickCancelSelect:(UIButton *)sender {
    [MobClick event:@"CancelSelect"];
    [UIView animateWithDuration:0.5f animations:^{
        if (self.newState == 1) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseScene.frame = CGRectMake(11, SCREEN_HEIGHT - 56, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseScene.hidden = NO;
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(11, 11, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.toggleCameraBtn.hidden = NO;
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.flashButton.hidden = NO;
        }
        if (self.newState == 1) {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.bottom + 2, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.top - 15, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        self.sceneView.alpha = 0;
    } completion:^(BOOL finished) {
        self.sceneView.hidden = YES;
        self.alertLabel.hidden = YES;
        self.sureBtn.hidden = YES;
        self.giveUpBtn.hidden = YES;
        self.typeView.hidden = NO;
        self.seeRush.hidden = NO;
    }];
}

- (void)changeTypeToPlay {
    NSInteger num = selectType;
    //数据 url也放在这里
    DLYMiniVlogTemplate *template = typeModelArray[num];
    NSString *videoName = [template.sampleVideoName stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
    NSArray *urlArr = @[@"http://dly.oss-cn-shanghai.aliyuncs.com/UniversalTemplateSample.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/GourmandismTemplateSample.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/TravelerTemplateSample.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/ColorLifeTemplateSample.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/UniversalTemplateSample002.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/GourmandismTemplateSample002.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/TravelerTemplateSample002.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/ColorLifeTemplateSample002.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/UniversalTemplateSample003.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/GourmandismTemplateSample003.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/TravelerTemplateSample003.mp4",
                        @"http://dly.oss-cn-shanghai.aliyuncs.com/ColorLifeTemplateSample003.mp4"];
    NSString *videoUrl = urlArr[num];
    //路径
    NSString *finishPath = [kPathDocument stringByAppendingFormat:@"/FinishVideo/%@.mp4", videoName];
    NSString *tempPath = [kCachePath stringByAppendingFormat:@"/%@.mp4", videoName];
    NSString *finishFolder = [kPathDocument stringByAppendingFormat:@"/FinishVideo"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:finishFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:finishFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    DLYPlayVideoViewController *playVC = [[DLYPlayVideoViewController alloc] init];
    BOOL isExist = [[DLYDownloadManager shredManager] isExistLocalVideo:videoName andVideoURLString:videoUrl];
    if (isExist) {
        NSURL *url = [NSURL fileURLWithPath:finishPath];
        playVC.playUrl = url;
        playVC.isOnline = NO;
    }else {
        [[DLYDownloadManager shredManager] downloadWithUrlString:videoUrl toPath:tempPath process:^(float progress, NSString *sizeString, NSString *speedString) {
            //下载过程中
        } completion:^{
            //下载完成
            BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:tempPath toPath:finishPath error:nil];
            if (isSuccess) {
                DLYLog(@"rename success");
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            }else{
                DLYLog(@"rename fail");
            }
        } failure:^(NSError *error) {
            //失败
            [[DLYDownloadManager shredManager] cancelDownloadTask:videoUrl];
        }];
        
        playVC.playUrl = [NSURL URLWithString:videoUrl];
        playVC.isOnline = YES;
    }
    playVC.isAll = NO;
    playVC.beforeState = self.newState;
    self.isPlayer = YES;
    [self hideBubbleWhenPush];
    [self.navigationController pushViewController:playVC animated:YES];
}
//取消拍摄按键
- (void)onClickCancelClick:(UIButton *)sender {
    [MobClick event:@"CancelRecord"];
    [self.AVEngine cancelRecording];
    
    NSInteger partNum = selectPartTag - 10000 - 1;
    [self.resource removePartWithPartNumFormCache:partNum];
    
    dispatch_source_cancel(_timer);
    _timer = nil;
    
    [UIView animateWithDuration:0.5f animations:^{
        self.progressView.hidden = YES;
        self.timeNumber.hidden = YES;
        if (self.newState == 1) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseScene.frame = CGRectMake(11, SCREEN_HEIGHT - 56, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseScene.hidden = NO;
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(11, 11, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.toggleCameraBtn.hidden = NO;
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.flashButton.hidden = NO;
        }
        if (self.newState == 1) {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.bottom + 2, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.top - 15, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        self.backView.transform = CGAffineTransformMakeTranslation(0, 0);
        self.shootView.alpha = 0;
    } completion:^(BOOL finished) {
        self.shootView.hidden = YES;
        
    }];
    
}
//删除某个片段的具体操作
- (void)deleteSelectPartVideo {
    
    NSInteger i = selectPartTag - 10000;
    
    DLYMiniVlogPart *part = partModelArray[i-1];
    
    [UIView animateWithDuration:0.5f animations:^{
        
        self.playView.hidden = YES;
        self.recordBtn.hidden = NO;
    } completion:^(BOOL finished) {
        
    }];
    
    for(int i = 0; i < partModelArray.count; i++)
    {
        DLYMiniVlogPart *part1 = partModelArray[i];
        part1.prepareRecord = @"0";
    }
    part.prepareRecord = @"0";
    part.recordStatus = @"0";
    
    NSInteger n = 0;
    for(int i = 0; i < partModelArray.count; i++)
    {
        DLYMiniVlogPart *part2 = partModelArray[i];
        
        if([part2.recordStatus isEqualToString:@"0"])
        {
            part2.prepareRecord = @"1";
            break;
        }else
        {
            n++;
        }
    }
    
    //判断
    for (DLYMiniVlogPart *part3 in partModelArray) {
        if ([part3.recordStatus isEqualToString:@"0"]) {
            self.nextButton.hidden = YES;
            if (self.allBubble) {
                [self.allBubble removeFromSuperview];
                self.allBubble = nil;
            }
            self.deleteButton.selected = NO;
            self.deleteButton.backgroundColor = RGBA(0, 0, 0, 0.4);
            self.deleteButton.hidden = YES;
            self.isSuccess = NO;
        }
    }
    [self createPartViewLayout];
}

- (void)createPartViewLayout {
    
    if (self.newState == 1) {
        [self createPartView];
    }else if (self.newState == 2){
        [self createLeftPartView];
    }
}

#pragma mark ==== 拍摄片段的view 暂定6个item
- (void)createPartView {
    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HEIGHT - 30  * SCALE_HEIGHT - (partModelArray.count - 1) * 2)/ partModelArray.count;
    
    if(SCREEN_HEIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - (partModelArray.count - 1) * 2) / partModelArray.count;
    }
    [self.toggleCameraBtn setImage:[UIImage imageWithIcon:@"\U0000e668" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    isSlomoCamera = NO;
    BOOL isAllPart = YES;
    for(int i = 1; i <= partModelArray.count; i ++)
    {
        DLYMiniVlogPart *part = partModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(43, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        button.tag = 10000 + i;
        UIEdgeInsets edgeInsets = {0, -43, 0, -5};
        [button setHitEdgeInsets:edgeInsets];
        //辨别改变段是否已经拍摄
        if([part.recordStatus isEqualToString:@"1"])
        {
            button.backgroundColor = RGB(255, 0, 0);
            //显示标注
            if(part.recordType == DLYMiniVlogRecordTypeNormal)
            {
                UILabel * timeLabel = [[UILabel alloc] init];
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [timeLabel sizeToFit];
                timeLabel.frame = CGRectMake(button.left - 4 - timeLabel.width, 0, timeLabel.width, timeLabel.height);
                timeLabel.centerY = button.centerY;
                [self.backScrollView addSubview:timeLabel];
                
            }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
            {//慢动作
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"慢镜";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }else
            {//延时
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"快镜";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }
        }else
        {
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            // 辨别该片段是否是默认准备拍摄片段
            if([part.prepareRecord isEqualToString:@"1"]){
                isAllPart = NO;
                selectPartTag = button.tag;
                //光标
                button.backgroundColor = RGB(168, 175, 180);
                prepareTag = button.tag;
                oldPrepareTag = prepareTag;
                prepareAlpha = 1;
                [_prepareShootTimer setFireDate:[NSDate distantPast]];
                
                //拍摄说明视图
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                itemView.tag = 30000 + i;
                [self.backScrollView addSubview:itemView];
                //判断拍摄状态
                if(part.recordType == DLYMiniVlogRecordTypeNormal)
                {//正常状态
                    UILabel * timeLabel = [[UILabel alloc] init];
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [timeLabel sizeToFit];
                    timeLabel.frame = CGRectMake(itemView.width - timeLabel.width, (itemView.height - timeLabel.height) / 2, timeLabel.width, timeLabel.height);
                    [itemView addSubview:timeLabel];
                    
                }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
                {//慢进
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"慢镜";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                    
                    //判断切换摄像头
                    if (self.toggleCameraBtn.selected) {
                        [self.AVEngine changeCameraInputDeviceisFront:NO];
                        self.toggleCameraBtn.selected = NO;
                        isFront = NO;
                        if (self.newState == 1) {
                            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                            self.flashButton.transform = CGAffineTransformMakeRotation(0);
                        }else {
                            self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                            self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
                        }
                        self.flashButton.hidden = NO;
                    }
                    [self.toggleCameraBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
                    isSlomoCamera = YES;
                }else
                {//延时
                    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"快镜";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }
            }
        }
        
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
    if (isAllPart) {
        //光标
        prepareTag = 10001;
        oldPrepareTag = prepareTag;
        prepareAlpha = 1;
        [_prepareShootTimer setFireDate:[NSDate distantPast]];
    }
}
- (void)createLeftPartView {
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HEIGHT - 30  * SCALE_HEIGHT - (partModelArray.count - 1) * 2)/ partModelArray.count;
    
    if(SCREEN_HEIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - (partModelArray.count - 1) * 2) / partModelArray.count;
    }
    
    NSMutableArray *leftModelArray = [NSMutableArray arrayWithArray:partModelArray];
    leftModelArray = (NSMutableArray *)[[leftModelArray reverseObjectEnumerator] allObjects];
    [self.toggleCameraBtn setImage:[UIImage imageWithIcon:@"\U0000e668" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    isSlomoCamera = NO;
    BOOL isAllPart = YES;
    for(int i = 1; i <= leftModelArray.count; i ++)
    {
        DLYMiniVlogPart *part = leftModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(43, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        button.tag = 10000 + (partModelArray.count + 1 - i);
        UIEdgeInsets edgeInsets = {0, -43, 0, -20};
        [button setHitEdgeInsets:edgeInsets];
        //辨别改变段是否已经拍摄
        if([part.recordStatus isEqualToString:@"1"])
        {
            button.backgroundColor = RGB(255, 0, 0);
            //显示标注
            if(part.recordType == DLYMiniVlogRecordTypeNormal)
            {
                UILabel * timeLabel = [[UILabel alloc] init];
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [timeLabel sizeToFit];
                timeLabel.frame = CGRectMake(button.left - 4 - timeLabel.width, 0, timeLabel.width, timeLabel.height);
                timeLabel.centerY = button.centerY;
                timeLabel.transform = CGAffineTransformMakeRotation(M_PI);
                [self.backScrollView addSubview:timeLabel];
                
            }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
            {//快进
                
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                itemView.transform = CGAffineTransformMakeRotation(M_PI);
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"慢镜";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
                
            }else
            {//延时
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                itemView.transform = CGAffineTransformMakeRotation(M_PI);
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentRight;
                timeLabel.textColor = [UIColor whiteColor];
                timeLabel.font = FONT_SYSTEM(11);
                NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                [itemView addSubview:timeLabel];
                
                UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                speedLabel.textColor = [UIColor whiteColor];
                speedLabel.font = FONT_SYSTEM(11);
                speedLabel.text = @"快镜";
                [itemView addSubview:speedLabel];
                
                UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }
        }else
        {
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            // 辨别该片段是否是默认准备拍摄片段
            if([part.prepareRecord isEqualToString:@"1"])
            {
                isAllPart = NO;
                selectPartTag = button.tag;
                //光标
                button.backgroundColor = RGB(168, 175, 180);
                prepareTag = button.tag;
                oldPrepareTag = prepareTag;
                prepareAlpha = 1;
                [_prepareShootTimer setFireDate:[NSDate distantPast]];
                //拍摄说明视图
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 39, 28)];
                itemView.centerY = button.centerY;
                itemView.transform = CGAffineTransformMakeRotation(M_PI);
                itemView.tag = 30000 + (partModelArray.count + 1 - i);
                [self.backScrollView addSubview:itemView];
                //判断拍摄状态
                if(part.recordType == DLYMiniVlogRecordTypeNormal)
                {//正常状态
                    UILabel * timeLabel = [[UILabel alloc] init];
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [timeLabel sizeToFit];
                    timeLabel.frame = CGRectMake(4, (itemView.height - timeLabel.height) / 2, timeLabel.width, timeLabel.height);
                    [itemView addSubview:timeLabel];
                    
                }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
                {//慢镜
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"慢镜";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                    
                    //判断切换摄像头
                    if (self.toggleCameraBtn.selected) {
                        [self.AVEngine changeCameraInputDeviceisFront:NO];
                        self.toggleCameraBtn.selected = NO;
                        isFront = NO;
                        if (self.newState == 1) {
                            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                            self.flashButton.transform = CGAffineTransformMakeRotation(0);
                        }else {
                            self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                            self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
                        }
                        self.flashButton.hidden = NO;
                    }
                    [self.toggleCameraBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
                    isSlomoCamera = YES;
                }else
                {//延时
                    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    NSArray *timeArr = [part.partTime componentsSeparatedByString:@"."];
                    timeLabel.text = [NSString stringWithFormat:@"%@%@", timeArr[0], @"''"];
                    [itemView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 14, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"快镜";
                    [itemView addSubview:speedLabel];
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 14, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }
            }
        }
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
    
    if (isAllPart) {
        //光标
        prepareTag = 10001;
        oldPrepareTag = prepareTag;
        prepareAlpha = 1;
        [_prepareShootTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)prepareShootAction {
    
    if (oldPrepareTag != prepareTag) {
        DLYMiniVlogPart *part = partModelArray[oldPrepareTag - 10001];
        if([part.recordStatus isEqualToString:@"1"]){
            UIButton *button = (UIButton *)[self.view viewWithTag:oldPrepareTag];
            button.backgroundColor = RGB(255, 0, 0);
            button.alpha = 1;
        }else {
            UIButton *button = (UIButton *)[self.view viewWithTag:oldPrepareTag];
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            button.alpha = 1;
        }
    }
    oldPrepareTag = prepareTag;
    if (prepareTag == 0) {
        return;
    }
    [UIView animateWithDuration:0.1f animations:^{
        if(prepareAlpha == 1)
        {
            UIButton *button = (UIButton *)[self.view viewWithTag:prepareTag];
            button.alpha = 0;
        }else
        {
            UIButton *button = (UIButton *)[self.view viewWithTag:prepareTag];
            button.alpha = 1;
        }
    } completion:^(BOOL finished) {
        if(prepareAlpha == 1)
        {
            prepareAlpha = 0;
        }else
        {
            prepareAlpha = 1;
        }
        
    }];
}

#pragma mark ==== 每个拍摄片段的点击事件
- (void)vedioEpisodeClick:(UIButton *)sender {
    UIButton * button = (UIButton *)sender;
    NSInteger i = button.tag - 10000;
    selectPartTag = button.tag;
    DLYMiniVlogPart *part = partModelArray[i-1];
    //点击哪个item，光标移动到当前item
    prepareTag = button.tag;
    
    if([part.recordStatus isEqualToString:@"1"])
    {//说明时已拍摄片段
        
        for (DLYMiniVlogPart *part in partModelArray) {
            if ([part.prepareRecord isEqualToString:@"1"]) {
                NSInteger i = [partModelArray indexOfObject:part];
                UIView *view = (UIView *)[self.view viewWithTag:30001 + i];
                [view removeFromSuperview];
            }
        }
        
        DDLogInfo(@"点击了已拍摄片段");
        [UIView animateWithDuration:0.5f animations:^{
            if (self.newState == 1) {
                self.playButton.transform = CGAffineTransformMakeRotation(0);
                self.deletePartButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.playButton.transform = CGAffineTransformMakeRotation(M_PI);
                self.deletePartButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            cursorTag = selectPartTag;
            self.playView.hidden = NO;
            self.recordBtn.hidden = YES;
        } completion:^(BOOL finished) {
            if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showPlayButtonPopup"]){
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showPlayButtonPopup"];
                DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.playButton titles:@[@"预览视频片段"] icons:nil menuWidth:120 delegate:self];
                normalBubble.showMaskAlpha = 1;
            }
        }];
    }else
    {
        if (!self.playView.isHidden && self.playView) {
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
            self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
            self.playView.hidden = YES;
        }
        self.recordBtn.hidden = NO;
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogPart *part1 = partModelArray[i];
            part1.prepareRecord = @"0";
        }
        part.prepareRecord = @"1";
        
        [self createPartViewLayout];
        
    }
    
}
#pragma mark ==== 创建选择场景view
- (void)createSceneView {
    [self.view addSubview:[self sceneView]];
    self.scenceDisapper = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 14, 14)];
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [self.scenceDisapper setHitEdgeInsets:edgeInsets];
    [self.scenceDisapper setImage:[UIImage imageWithIcon:@"\U0000e666" inFont:ICONFONT size:14 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.scenceDisapper addTarget:self action:@selector(onClickCancelSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self.sceneView addSubview:self.scenceDisapper];
    
    self.chooseTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 130, 28)];
    self.chooseTitleLabel.centerX = self.sceneView.centerX;
    self.chooseTitleLabel.textColor = RGB(255, 255, 255);
    self.chooseTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.chooseTitleLabel.font = FONT_SYSTEM(20);
    self.chooseTitleLabel.text = @"选择拍摄场景";
    [self.sceneView addSubview:self.chooseTitleLabel];
    
    self.seeRush = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 70, 21, 50, 17)];
    [self.seeRush setImage:[UIImage imageWithIcon:@"\U0000e63f" inFont:ICONFONT size:12 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.seeRush setTitle:@"样片" forState:UIControlStateNormal];
    [self.seeRush setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.seeRush.titleLabel.font = FONT_SYSTEM(12);
    [self.seeRush setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, -4)];
    [self.seeRush setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 4)];
    UIEdgeInsets seeRushedgeInsets = {-10, -10, -10, -10};
    [self.seeRush setHitEdgeInsets:seeRushedgeInsets];
    [self.seeRush addTarget:self action:@selector(changeTypeToPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.sceneView addSubview:self.seeRush];
    
    self.typeView = [[UIView alloc]initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 80, 190)];
    self.typeView.centerY = self.sceneView.centerY;
    [self.sceneView addSubview:self.typeView];
    UIScrollView * typeScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.typeView.width, self.typeView.height)];
    typeScrollView.showsVerticalScrollIndicator = NO;
    typeScrollView.showsHorizontalScrollIndicator = NO;
    typeScrollView.bounces = NO;
    [self.typeView addSubview:typeScrollView];
    
    float width = (self.typeView.width - 50)/6;
    typeScrollView.contentSize = CGSizeMake(width * 6 + 10 * 5, typeScrollView.height);
    for(int i = 0; i < typeModelArray.count; i ++)
    {
        int wNum = i % 6;
        int hNum = i / 6;
        DLYMiniVlogTemplate *templateModel = typeModelArray[i];
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake((width + 10) * wNum, 100 * hNum, width, 90)];
        view.tag = 101 + i;
        [typeScrollView addSubview:view];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 61, 61)];
        btn.tag = 1002 + i;
        btn.centerX = view.width / 2;
        [btn setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changeTypeStatus:) forControlEvents:UIControlEventTouchUpInside];
        btn.layer.cornerRadius = 30.5;
        btn.clipsToBounds = YES;
        btn.layer.borderWidth = 1,0;
        btn.layer.borderColor = RGB(255, 255, 255).CGColor;
        [view addSubview:btn];
        
        UILabel *typeName = [[UILabel alloc]initWithFrame:CGRectMake(0, btn.bottom + 7, 55, 22)];
        typeName.tag = 2002 + i;
        typeName.centerX = view.width / 2;
        typeName.text = templateModel.templateTitle;
        typeName.textColor = RGB(255, 255, 255);
        typeName.font = FONT_SYSTEM(16);
        typeName.textAlignment = NSTextAlignmentCenter;
        [view addSubview:typeName];
        
        if(i == selectType) {
            [btn setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 122, 0, 1)] forState:UIControlStateNormal];
            btn.layer.borderColor = RGB(255, 122, 0).CGColor;
            typeName.textColor = RGB(255, 122, 0);
        }
    }
    
    self.alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 210, 368, 22)];
    self.alertLabel.centerX = self.sceneView.centerX;
    self.alertLabel.textColor = RGB(255, 255, 255);
    self.alertLabel.textAlignment = NSTextAlignmentCenter;
    self.alertLabel.font = FONT_SYSTEM(16);
    self.alertLabel.text = @"之前拍摄的不会保存,确定切换模板,重新拍摄?";
    self.alertLabel.hidden = YES;
    [self.sceneView addSubview:self.alertLabel];
    
    self.sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.alertLabel.bottom + 20, 61, 61)];
    self.sureBtn.centerX = self.sceneView.centerX - 46;
    [self.sureBtn setImage:[UIImage imageWithIcon:@"\U0000e602" inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.sureBtn addTarget:self action:@selector(onSureClickChangeTypeStatus) forControlEvents:UIControlEventTouchUpInside];
    self.sureBtn.layer.cornerRadius = 30.5;
    self.sureBtn.clipsToBounds = YES;
    self.sureBtn.layer.borderWidth = 1,0;
    self.sureBtn.layer.borderColor = RGB(255, 255, 255).CGColor;
    self.sureBtn.hidden = YES;
    [self.sceneView addSubview:self.sureBtn];
    
    self.giveUpBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.alertLabel.bottom + 20, 61, 61)];
    self.giveUpBtn.centerX = self.sceneView.centerX  + 46;
    [self.giveUpBtn setImage:[UIImage imageWithIcon:@"\U0000e666" inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.giveUpBtn addTarget:self action:@selector(onGiveUpClickChangeTypeStatus) forControlEvents:UIControlEventTouchUpInside];
    self.giveUpBtn.layer.cornerRadius = 30.5;
    self.giveUpBtn.clipsToBounds = YES;
    self.giveUpBtn.layer.borderWidth = 1,0;
    self.giveUpBtn.layer.borderColor = RGB(255, 255, 255).CGColor;
    self.giveUpBtn.hidden = YES;
    [self.sceneView addSubview:self.giveUpBtn];
    
}
//确定切换模板
- (void)onSureClickChangeTypeStatus {
    
    [self.resource removeCurrentAllPartFromCache];
    [self.resource removeCurrentAllPartFromDocument];
    
    //数组初始化，view布局
    if (!self.deleteButton.isHidden && self.deleteButton) {
        if (self.allBubble) {
            [self.allBubble removeFromSuperview];
            self.allBubble = nil;
        }
        self.deleteButton.selected = NO;
        self.deleteButton.backgroundColor = RGBA(0, 0, 0, 0.4);
        self.deleteButton.hidden = YES;
    }
    if (!self.nextButton.isHidden && self.nextButton) {
        self.nextButton.hidden = YES;
    }
    if (!self.playView.isHidden && self.playView) {
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
        self.deletePartButton.selected = NO;
        [self.deletePartButton setImage:[UIImage imageWithIcon:@"\U0000e667" inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        self.playView.hidden = YES;
    }
    if (self.recordBtn.isHidden && self.recordBtn) {
        self.recordBtn.hidden = NO;
    }
    [self changeSceneWithSelectNum:selectNewPartTag];
    [self initData];
    [self createPartViewLayout];
    
    self.alertLabel.hidden = YES;
    self.sureBtn.hidden = YES;
    self.giveUpBtn.hidden = YES;
    self.typeView.hidden = NO;
    self.seeRush.hidden = NO;
}
//放弃切换模板
- (void)onGiveUpClickChangeTypeStatus {
    
    self.alertLabel.hidden = YES;
    self.sureBtn.hidden = YES;
    self.giveUpBtn.hidden = YES;
    self.typeView.hidden = NO;
    self.seeRush.hidden = NO;
}


#pragma mark === 更改样片选中状态
- (void)changeTypeStatus:(UIButton *)sender {
    
    NSInteger num = sender.tag - 1002;
    
    if(num == selectType) {
        return;
    }
    
    BOOL isEmpty = YES;
    for (DLYMiniVlogPart *part in partModelArray) {
        if ([part.recordStatus isEqualToString:@"1"]) {
            isEmpty = NO;
        }
    }
    
    if (isEmpty) {
        //数组初始化，view布局 弹出选择
        [self.resource removeCurrentAllPartFromCache];
        [self changeSceneWithSelectNum:num];
        [self initData];
        [self createPartViewLayout];
    }else {
        
        selectNewPartTag = num;
        self.typeView.hidden = YES;
        self.seeRush.hidden = YES;
        if (self.newState == 1) {
            self.alertLabel.frame = CGRectMake(0, 210, 368, 22);
            self.alertLabel.centerX = self.sceneView.centerX;
            self.alertLabel.transform = CGAffineTransformMakeRotation(0);
            self.sureBtn.frame = CGRectMake(0, self.alertLabel.bottom + 20, 61, 61);
            self.sureBtn.centerX = self.sceneView.centerX - 46;
            self.sureBtn.transform = CGAffineTransformMakeRotation(0);
            self.giveUpBtn.frame = CGRectMake(0, self.alertLabel.bottom + 20, 61, 61);
            self.giveUpBtn.centerX = self.sceneView.centerX  + 46;
            self.giveUpBtn.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.alertLabel.frame = CGRectMake(0, SCREEN_HEIGHT - 232, 368, 22);
            self.alertLabel.centerX = self.sceneView.centerX;
            self.alertLabel.transform = CGAffineTransformMakeRotation(M_PI);
            self.sureBtn.frame = CGRectMake(0, self.alertLabel.top - 81, 61, 61);
            self.sureBtn.centerX = self.sceneView.centerX + 46;
            self.sureBtn.transform = CGAffineTransformMakeRotation(M_PI);
            self.giveUpBtn.frame = CGRectMake(0, self.alertLabel.top - 81, 61, 61);
            self.giveUpBtn.centerX = self.sceneView.centerX - 46;
            self.giveUpBtn.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.alertLabel.hidden = NO;
        self.sureBtn.hidden = NO;
        self.giveUpBtn.hidden = NO;
    }
}

- (void)changeSceneWithSelectNum:(NSInteger)num {
    
    selectType = num;
    DLYMiniVlogTemplate *template = typeModelArray[num];
    self.chooseSceneLabel.text = template.templateTitle;
    [self.session saveCurrentTemplateWithId:template.templateId];
    
    for(int i = 0; i < typeModelArray.count; i++) {
        UIButton *btn = (UIButton *)[self.view viewWithTag:1002 + i];
        UILabel * typeName = (UILabel *)[self.view viewWithTag:2002 + i];
        if(num == i)
        {
            [btn setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 122, 0, 1)] forState:UIControlStateNormal];
            btn.layer.borderColor = RGB(255, 122, 0).CGColor;
            typeName.textColor = RGB(255, 122, 0);
            [self.chooseScene setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
            
        }else
        {
            [btn setImage:[UIImage imageWithIcon:self.btnImg[i] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
            btn.layer.borderColor = RGB(255, 255, 255).CGColor;
            typeName.textColor = RGB(255, 255, 255);
        }
    }
    [UIView animateWithDuration:0.5f animations:^{
        self.sceneView.alpha = 0;
        if (self.newState == 1) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseScene.frame = CGRectMake(11, SCREEN_HEIGHT - 56, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(M_PI);
        }
        
        self.chooseScene.hidden = NO;
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(11, 11, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.toggleCameraBtn.hidden = NO;
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.flashButton.hidden = NO;
        }
        if (self.newState == 1) {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.bottom + 2, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.top - 15, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        
    } completion:^(BOOL finished) {
        self.sceneView.hidden = YES;
        
    }];
}

#pragma mark ==== 创建拍摄界面
- (void)createShootView {
    
    self.warningIcon = [[UIImageView alloc]initWithFrame:CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32)];
    self.warningIcon.hidden = YES;
    self.warningIcon.image = [UIImage imageWithIcon:@"\U0000e663" inFont:ICONFONT size:32 color:[UIColor redColor]];
    [self.shootView addSubview:self.warningIcon];
    
    self.shootGuide = [[UILabel alloc] init];
    if (self.newState == 1) {
        self.shootGuide.frame = CGRectMake(0, SCREEN_HEIGHT - 49, 270, 30);
        self.shootGuide.centerX = _shootView.centerX;
        self.shootGuide.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.shootGuide.frame = CGRectMake(0, 19, 270, 30);
        self.shootGuide.centerX = _shootView.centerX;
        self.shootGuide.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.shootGuide.backgroundColor = RGBA(0, 0, 0, 0.7);
    self.shootGuide.text = @"拍摄指导：请保持光线充足";
    self.shootGuide.textColor = RGB(255, 255, 255);
    self.shootGuide.font = FONT_SYSTEM(14);
    self.shootGuide.textAlignment = NSTextAlignmentCenter;
    [_shootView addSubview:self.shootGuide];
    
    _timeView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 70, 0, 60, 60)];
    _timeView.centerY = self.shootView.centerY;
    [self.shootView addSubview:_timeView];
    
    self.cancelButton = [[UIButton alloc] init];
    if (self.newState == 1) {
        self.cancelButton.frame = CGRectMake(0, _timeView.bottom + 40, 44, 44);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.cancelButton.frame = CGRectMake(0, _timeView.top - 84, 44, 44);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.cancelButton.backgroundColor = RGBA(0, 0, 0, 0.3);
    self.cancelButton.layer.cornerRadius = 22;
    self.cancelButton.clipsToBounds = YES;
    [self.cancelButton addTarget:self action:@selector(onClickCancelClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = FONT_SYSTEM(14);
    self.cancelButton.hidden = YES;
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [self.cancelButton setHitEdgeInsets:edgeInsets];
    [_shootView addSubview:self.cancelButton];
    
    _progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, _timeView.width, _timeView.height)];
    if (self.newState == 1) {
        self.progressView.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.progressView.transform = CGAffineTransformMakeRotation(M_PI);
    }
    _progressView.progress = 0.01;
    _progressView.circleRadius = 28;
    [_timeView addSubview:_progressView];
    
    //完成图片
    self.completeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.timeView.width, self.timeView.height)];
    self.completeButton.layer.borderWidth = 3.0;
    self.completeButton.layer.borderColor = RGB(255, 0, 0).CGColor;
    self.completeButton.layer.cornerRadius = self.timeView.width / 2.0;
    self.completeButton.clipsToBounds = YES;
    [self.completeButton setImage:[UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:30 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
    self.completeButton.hidden = YES;
    [_timeView addSubview:self.completeButton];
    
    self.timeNumber = [[UILabel alloc]initWithFrame:CGRectMake(3, 3, 54, 54)];
    if (self.newState == 1) {
        self.timeNumber.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.timeNumber.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.timeNumber.textColor = RGB(255, 255, 255);
    
    NSInteger partNumber = selectPartTag - 10000;
    DLYMiniVlogPart *part = partModelArray[partNumber - 1];
    NSArray *timeArr = [part.duration componentsSeparatedByString:@"."];
    self.timeNumber.text = timeArr[0];
    self.timeNumber.font = FONT_SYSTEM(20);
    self.timeNumber.textAlignment = NSTextAlignmentCenter;
    self.timeNumber.backgroundColor = RGBA(0, 0, 0, 0.3);
    self.timeNumber.layer.cornerRadius = 27;
    self.timeNumber.clipsToBounds = YES;
    [_timeView addSubview:self.timeNumber];
    ////
    NSString *partTitle = [NSString stringWithFormat:@"第%ld段",(long)part.partNum + 1];
    NSString *timeTitle = [NSString stringWithFormat:@"%@秒",timeArr[0]];
    NSString *typeTitle;
    if (part.recordType == DLYMiniVlogRecordTypeNormal) {
        typeTitle = @"正常";
    }else if (part.recordType == DLYMiniVlogRecordTypeSlomo) {
        typeTitle = @"慢镜头";
    }else {
        typeTitle = @"快镜头";
    }
    self.titleView = [[DLYTitleView alloc] initWithPartTitle:partTitle timeTitle:timeTitle typeTitle:typeTitle];
    if (self.newState == 1) {
        self.titleView.frame = CGRectMake(SCREEN_WIDTH - 190, 20, 180, 30);
        self.titleView.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.titleView.frame = CGRectMake(SCREEN_WIDTH - 190, SCREEN_HEIGHT - 50, 180, 30);
        self.titleView.transform = CGAffineTransformMakeRotation(M_PI);
    }
    [self.shootView addSubview:self.titleView];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0), 0.01 * NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shootAction];
        });
    });
    dispatch_resume(_timer);
    if (self.newState == 1) {
        self.cancelButton.frame = CGRectMake(0, _timeView.bottom + 40, 44, 44);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(0);
        
    }else {
        self.cancelButton.frame = CGRectMake(0, _timeView.top - 84, 44, 44);
        self.cancelButton.centerX = _timeView.centerX;
        self.cancelButton.transform = CGAffineTransformMakeRotation(M_PI);
    }
    self.cancelButton.hidden = NO;
    
}

#pragma mark ==== 拍摄计时操作
- (void)shootAction {
    
    NSInteger partNumber = selectPartTag - 10000;
    DLYMiniVlogPart *part = partModelArray[partNumber - 1];
    _shootTime += 0.01;
    
    if((int)(_shootTime * 100) % 100 == 0)
    {
        if (![self.timeNumber.text isEqualToString:@"1"]) {
            self.timeNumber.text = [NSString stringWithFormat:@"%.0f",[part.duration intValue] - _shootTime];
        }
    }
    
    double partDuration = [part.duration doubleValue];
    [_progressView drawProgress:_shootTime / partDuration];
    if(_shootTime > partDuration)
    {
        if (self.cancelButton.isHidden) {
            return;
        }
        isNeededToSave = YES;
        [self.AVEngine stopRecording];
        self.cancelButton.hidden = YES;
        dispatch_source_cancel(_timer);
        _timer = nil;
        
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogPart *part1 = partModelArray[i];
            part1.prepareRecord = @"0";
        }
        part.prepareRecord = @"0";
        part.recordStatus = @"1";
        
        NSInteger n = 0;
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogPart *part2 = partModelArray[i];
            if([part2.recordStatus isEqualToString:@"0"])
            {
                part2.prepareRecord = @"1";
                break;
            }else
            {
                n++;
                
            }
        }
        //在这里添加完成页面
        self.progressView.hidden = YES;
        self.timeNumber.hidden = YES;
        if (self.newState == 1) {
            self.completeButton.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.completeButton.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.completeButton.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.completeButton.hidden = YES;
        });
    }
}

- (void)showControlView {
    
    [self createPartViewLayout];
    
    [UIView animateWithDuration:0.5f animations:^{
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(11, 11, 40, 40);
            self.toggleCameraBtn.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.toggleCameraBtn.hidden = NO;
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.flashButton.frame = CGRectMake(11, 61, 40, 40);
                self.flashButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.flashButton.hidden = NO;
        }
        
        if (self.newState == 1) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseScene.frame = CGRectMake(11, SCREEN_HEIGHT - 56, 40, 40);
            self.chooseScene.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseScene.hidden = NO;
        if (self.newState == 1) {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.bottom + 2, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(0);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(11, self.chooseScene.top - 15, 40, 13);
            self.chooseSceneLabel.transform = CGAffineTransformMakeRotation(M_PI);
        }
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        self.backView.transform = CGAffineTransformMakeTranslation(0, 0);
        self.shootView.alpha = 0;
        self.shootView.hidden = YES;
    } completion:^(BOOL finished) {
    }];
}

- (void)indicatorViewstopFlashAnimating {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        
        [self showControlView];
        
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogPart *part = partModelArray[i];
            if ([part.recordStatus isEqualToString:@"0"]) {
                return;
            }
        }
        DDLogInfo(@"完成后跳转");
        self.recordBtn.hidden = YES;
        __weak typeof(self) weakSelf = self;
        DLYPlayVideoViewController * fvc = [[DLYPlayVideoViewController alloc]init];
        fvc.isAll = YES;
        fvc.isSuccess = NO;
        fvc.playUrl = self.AVEngine.currentProductUrl;
        fvc.beforeState = self.newState;
        self.isPlayer = YES;
        fvc.DismissBlock = ^{
            if (self.newState == 1) {
                self.nextButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.nextButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.nextButton.hidden = NO;
            if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showNextButtonPopup"]){
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNextButtonPopup"];
                DLYPopupMenu *normalBubble = [DLYPopupMenu showRelyOnView:self.nextButton titles:@[@"去合成视频"] icons:nil menuWidth:120 delegate:self];
                normalBubble.showMaskAlpha = 1;
            }
            if (self.newState == 1) {
                self.deleteButton.transform = CGAffineTransformMakeRotation(0);
            }else {
                self.deleteButton.transform = CGAffineTransformMakeRotation(M_PI);
            }
            self.deleteButton.hidden = NO;
            self.isSuccess = YES;
        };
        [self hideBubbleWhenPush];
        [weakSelf.navigationController pushViewController:fvc animated:YES];
    }
}

#pragma mark ==== 权限访问
- (BOOL)monitorPermission {
    //相机 麦克风 相册
    BOOL isCamera = [self checkVideoCameraAuthorization];
    BOOL isMicrophone = [self checkVideoMicrophoneAudioAuthorization];
    BOOL isPhoto = [self checkVideoPhotoAuthorization];
    
    if(isCamera && isMicrophone && isPhoto){
        return YES;
    }else {
        return NO;
    }
}
//监听通知，APP进入前台
- (void)recordViewWillEnterForeground {
    
    //相机 麦克风 相册
    [self checkVideoCameraAuthorization];
    [self checkVideoMicrophoneAudioAuthorization];
    [self checkVideoPhotoAuthorization];
}
//相册
- (BOOL)checkVideoPhotoAuthorization {
    __block BOOL isAvalible = NO;
    //iOS8.0之后
    PHAuthorizationStatus photoStatus =  [PHPhotoLibrary authorizationStatus];
    switch (photoStatus) {
        case PHAuthorizationStatusAuthorized:
            isAvalible = YES;
            break;
        case PHAuthorizationStatusDenied:
        {
            [self showAlertPermissionwithMessage:@"相册"];
            isAvalible = NO;
        }
            break;
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    isAvalible = YES;
                    BOOL isCamera = [self checkVideoCameraAuthorization];
                    BOOL isMicrophone = [self checkVideoMicrophoneAudioAuthorization];
                    if (isCamera && isMicrophone) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showCueBubble];
                        });
                    }
                }else{
                    isAvalible = NO;  //回到主线程
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertPermissionwithMessage:@"相册"];
                    });
                }
            }];
        }
            break;
        case PHAuthorizationStatusRestricted:
            isAvalible = NO;
            break;
        default:
            break;
    }
    
    return isAvalible;
}
//相机
- (BOOL)checkVideoCameraAuthorization {
    __block BOOL isAvalible = NO;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized: //授权
            isAvalible = YES;
            break;
        case AVAuthorizationStatusDenied:   //拒绝，弹框
        {
            [self showAlertPermissionwithMessage:@"相机"];
            isAvalible = NO;
        }
            break;
        case AVAuthorizationStatusNotDetermined:   //没有决定，第一次启动默认弹框
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                isAvalible = granted;
                if(!granted)  //如果不允许
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertPermissionwithMessage:@"相机"];
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:  //受限制，家长控制器
            isAvalible = NO;
            break;
    }
    return isAvalible;
}
//麦克风
- (BOOL)checkVideoMicrophoneAudioAuthorization {
    __block BOOL isAvalible = NO;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusAuthorized: //授权
            isAvalible = YES;
            break;
        case AVAuthorizationStatusDenied:   //拒绝，弹框
        {
            [self showAlertPermissionwithMessage:@"麦克风"];
            isAvalible = NO;
        }
            break;
        case AVAuthorizationStatusNotDetermined:   //没有决定，第一次启动
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                isAvalible = granted;
                if(!granted)  //如果不允许
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertPermissionwithMessage:@"麦克风"];
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:  //受限制，家长控制器
            isAvalible = NO;
            break;
    }
    return isAvalible;
}
//显示警告框
- (void)showAlertPermissionwithMessage:(NSString *)message {
    
    NSString *str = [NSString stringWithFormat:@"请到设置页面允许使用%@", message];
    self.alert = [[DLYAlertView alloc] initWithMessage:str withSureButton:@"确定"];
    
    if (self.newState == 1) {
        self.alert.transform = CGAffineTransformMakeRotation(0);
    }else {
        self.alert.transform = CGAffineTransformMakeRotation(M_PI);
    }
    __weak typeof(self) weakSelf = self;
    self.alert.sureButtonAction = ^{
        [weakSelf gotoSetting];
    };
}
//跳转到设置
- (void)gotoSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}

#pragma mark ==== 懒加载

- (UIView *)sceneView {
    if(_sceneView == nil)
    {
        _sceneView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _sceneView.backgroundColor = RGBA(0, 0, 0, 1);
        _sceneView.alpha = 0;
        _sceneView.hidden = YES;
    }
    return _sceneView;
}

- (UIView *)shootView {
    if(_shootView == nil)
    {
        _shootView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _shootView.backgroundColor = RGBA(247, 247, 247,0);
        _shootView.alpha = 0;
        _shootView.hidden = YES;
    }
    return _shootView;
}

- (DLYSession *)session {
    
    if (_session == nil) {
        _session = [[DLYSession alloc] init];
    }
    return _session;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
