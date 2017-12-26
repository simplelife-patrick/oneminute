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
#import "DLYTitleView.h"

#import "DLYPreviewView.h"
#import "DLYImageTarget.h"
#import "DLYContextManager.h"
#import "DLYPhotoFilters.h"
#import "DLYChooseFilterTableViewCell.h"

#import "UIImage+ImageEffects.h"
typedef void(^CompCompletedBlock)(BOOL success);
typedef void(^CompProgressBlcok)(CGFloat progress);

@interface DLYRecordViewController ()<DLYCaptureAVEngineDelegate,UIAlertViewDelegate,UIGestureRecognizerDelegate,YBPopupMenuDelegate,DLYIndicatorViewDelegate,UITableViewDelegate,UITableViewDataSource>
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
    NSMutableArray * partModelArray; //模拟存放拍摄片段的模型数组
    NSMutableArray * typeModelArray; //模拟选择样式的模型数组
    NSMutableArray * videoArray; //模拟选择样式的模型数组
    BOOL isMicGranted;//麦克风权限是否被允许
    BOOL isFront;
    BOOL isSlomoCamera;
    CGFloat _initialPinchZoom;
    CGFloat durationTime;
    double shootNum;
}
@property (nonatomic,assign) CGFloat                            beginGestureScale;//记录开始的缩放比例
@property (nonatomic,assign) CGFloat                            effectiveScale;//最后的缩放比例
@property (nonatomic, copy) NSArray                             *btnImg;//场景对应的图片
@property (nonatomic, strong) DLYAVEngine                       *AVEngine;
@property (nonatomic, strong) DLYPreviewView                    *previewView;
@property (nonatomic, weak) id <DLYImageTarget>                 imageTarget;
@property (nonatomic, strong) UIImageView                       *previewMaskView;
@property (nonatomic, strong) UIImageView                       *previewBlurView;
@property (nonatomic, strong) UIImageView                       *previewStaticView;
@property (nonatomic, strong) UIImageView                       *focusCursorImageView;
@property (nonatomic, strong) UIImageView                       *faceRegionImageView;
@property (nonatomic, strong) UIView * sceneView; //选择场景的view
@property (nonatomic, strong) UIView * filterView; //选择filter的view
@property (nonatomic, strong) UIView * filterContentView; //选择filter的背景view
@property (nonatomic, strong) UIView * videoView; //选择样片的view
@property (nonatomic, strong) UIView * shootView; //拍摄界面
@property (nonatomic, strong) UIView * timeView;
@property (nonatomic, strong) NSTimer * prepareShootTimer; //准备拍摄片段闪烁的计时器
@property (nonatomic, strong) DLYAnnularProgress * progressView;    //环形进度条
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) DLYAlertView *alert;          //警告框
@property (nonatomic, strong) DLYTitleView *titleView;      //拍摄说明
@property (nonatomic, strong) UIButton *chooseScene;        //选择场景
@property (nonatomic, strong) UILabel *chooseSceneLabel;    //选择场景文字
@property (nonatomic, strong) UIButton *chooseFilter;        //选择滤镜
@property (nonatomic, strong) UILabel *chooseFilterLabel;    //选择滤镜文字
@property (nonatomic, strong) UIButton *toggleCameraBtn;    //切换摄像头
@property (nonatomic, strong) UIButton *flashButton;        //闪光灯
@property (nonatomic, strong) UIView *backView;             //控制页面底层
@property (nonatomic, strong) UIButton *recordBtn;          //拍摄按钮
@property (nonatomic, strong) UIButton *nextButton;         //下一步按钮
@property (nonatomic, strong) UIButton *deleteButton;       //删除全部按钮
@property (nonatomic, strong) UIScrollView *backScrollView; //片段展示滚图
@property (nonatomic, strong) UIView *playView;             //单个片段编辑页面
@property (nonatomic, strong) UIButton *playButton;         //播放单个视频
@property (nonatomic, strong) UIButton *deletePartButton;   //删除单个视频
@property (nonatomic, strong) UIButton *sceneDisapper;      //取消选择模板
@property (nonatomic, strong) UIButton *videoDisapper;      //取消观看样片
@property (nonatomic, strong) UIImageView *warningIcon;     //拍摄指导
@property (nonatomic, strong) UILabel *shootGuide;          //拍摄指导
@property (nonatomic, strong) UIButton *cancelButton;       //取消拍摄
@property (nonatomic, strong) UIButton *completeButton;     //拍摄单个片段完成
@property (nonatomic, strong) UILabel *timeNumber;          //倒计时显示label
@property (nonatomic, strong) DLYResource  *resource;       //资源管理类
@property (nonatomic, strong) DLYSession *session;          //录制会话管理类
@property (nonatomic, strong) UILabel *chooseTitleLabel;    //选择场景说明
@property (nonatomic, strong) UILabel *videoTitleLabel;     //选择样片说明
@property (nonatomic, strong) UIButton *seeRush;            //观看样片
@property (nonatomic, strong) UILabel *alertLabel;          //提示文字
@property (nonatomic, strong) UIButton *sureBtn;            //确定切换场景
@property (nonatomic, strong) UIButton *giveUpBtn;          //放弃切换场景
@property (nonatomic, strong) UIView *typeView;             //场景view
@property (nonatomic, strong) UIView *filmView;             //样片view
@property (nonatomic, strong) DLYPopupMenu *partBubble;     //删除单个气泡
@property (nonatomic, strong) DLYPopupMenu *allBubble;      //删除全部气泡
@property (nonatomic, strong) DLYPopupMenu *normalBubble;   //普通气泡
@property (nonatomic, strong) DLYPopupMenu *nextStepBubble; //去合成视频气泡
@property (nonatomic, strong) NSMutableArray *viewArr;      //视图数组
@property (nonatomic, strong) NSMutableArray *bubbleTitleArr;//视图数组
@property (nonatomic, assign) BOOL isAvalible;              //权限都已经许可
//@property (nonatomic, strong) UILabel *versionLabel;        //版本显示
@property (nonatomic, assign)BOOL isFilterTableViewHasSelected;   //第一次时手动把无滤镜选中
@end

@implementation DLYRecordViewController
-(void)startedRecording{
    DLYLog(@"开始了");
}
-(void)finishedRecordingByConsuming{
    DLYLog(@"结束了");
}
-(void)canceledRecording{
    DLYLog(@"结束了");
}
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
    [DLYUserTrack recordAndEventKey:@"RecordViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"RecordView"];
    if (self.newState == 1) {
        [self deviceChangeAndHomeOnTheRightNewLayout];
    }else {
        [self deviceChangeAndHomeOnTheLeftNewLayout];
    }
    
    if (self.isExport) {
        
        [self initData];
        if (!self.deleteButton.isHidden && self.deleteButton) {
            [self.allBubble dismiss];
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
            [self.partBubble dismiss];
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
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
    
    if (!self.playView.isHidden && self.playView) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showPlayButtonPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showPlayButtonPopup"];
            self.normalBubble = [DLYPopupMenu showRelyOnView:self.playButton titles:@[@"预览视频片段"] icons:nil menuWidth:120 withState:self.newState delegate:self];
            self.normalBubble.showMaskAlpha = 1;
            self.normalBubble.flipState = self.newState;
        }
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.AVEngine pauseRecording];
    [DLYUserTrack recordAndEventKey:@"RecordViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"RecordView"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isAvalible = [self monitorPermission];
    
    [self.session detectionTemplateForLaunchComplated:^(BOOL isChangeAndCleared) {
        DLYLog(@"%d",isChangeAndCleared ? @"启动检测 - 当前保存的模板版本已升级,且存在旧模板拍摄的草稿,已被清空重新加载升级模板的数据!":@"启动检测 - 模板未升级");
    }];
    
    [DLYIndicatorView sharedIndicatorView].delegate = self;
    //    [self initData];
    NSInteger draftNum = [self initDataReadDraft];
    [self setupUI];
    [self initializationRecorder];
    
    //进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordViewWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (draftNum == partModelArray.count) {
        self.recordBtn.hidden = YES;
        self.isSuccess = YES;
        if (self.newState == 1) {
            self.nextButton.center = self.view.center;
            self.deleteButton.frame = CGRectMake(self.view.centerX - 121, self.view.centerY - 30, 60, 60);
        }else {
            self.deleteButton.center = self.view.center;
            self.nextButton.frame = CGRectMake(self.view.centerX + 61, self.view.centerY - 30, 60, 60);
        }
        self.nextButton.hidden = NO;
        self.deleteButton.hidden = NO;
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showNextButtonPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNextButtonPopup"];
            self.nextStepBubble = [DLYPopupMenu showNextStepOnView:self.nextButton titles:@[@"去合成视频"] icons:nil menuWidth:120 withState:self.newState delegate:self];
            self.nextStepBubble.showMaskAlpha = 1;
            self.nextStepBubble.nextStepState = self.newState;
        }
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
        NSArray *titleArr = @[@"选择场景", @"补光灯", @"切换摄像头", @"录制视频"];
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
    self.normalBubble = [DLYPopupMenu showRelyOnView:btn titles:titles icons:nil menuWidth:120 withState:self.newState delegate:self];
    self.normalBubble.showMaskAlpha = 1;
    self.normalBubble.flipState = self.newState;
    [self.viewArr removeObjectAtIndex:0];
    [self.bubbleTitleArr removeObjectAtIndex:0];
}
//气泡消失的代理方法
- (void)ybPopupMenuDidDismiss {
    if (self.normalBubble) {
        [self.normalBubble removeFromSuperview];
        self.normalBubble = nil;
    }
    if (self.nextStepBubble) {
        [self.nextStepBubble removeFromSuperview];
        self.nextStepBubble = nil;
    }
    if (self.allBubble) {
        [self.allBubble removeFromSuperview];
        self.allBubble = nil;
    }
    if (self.partBubble) {
        [self.partBubble removeFromSuperview];
        self.partBubble = nil;
    }
    [self showPopupMenu];
}

#pragma mark ==== 初始化数据
- (NSInteger)initDataReadDraft {
    self.btnImg = @[@(IFPrimary), @(IFSecondary), @(IFAdvanced), @(IFGoNorth),
                    @(IFMyMaldives), @(IFBigMeal), @(IFAfternoonTea), @(IFDelicious),
                    @(IFColorfulLife), @(IFSunSetBeach), @(IFYoungOuting), @(IFSpiritTerritory)];

    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    [[DLYPhotoFilters sharedInstance]changeToName:template.filterName];
    if (self.session.currentTemplate.previewBorderName) {
        self.previewMaskView.image = [UIImage imageNamed:self.session.currentTemplate.previewBorderName];
    }else{
        self.previewMaskView.image = nil;
    }
    BOOL isExitDraft = [self.session isExistDraftAtFile];
    NSMutableArray *draftArr = [NSMutableArray array];
    if (isExitDraft) {
        NSArray *arr = [self.resource loadVirtualPartsFromDocument];
        for (NSURL *url in arr) {
            NSString *partPath = url.path;
            NSString *newPath = [partPath stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
            NSArray *arr = [newPath componentsSeparatedByString:@"part"];
            NSString *partNum = arr.lastObject;
            [draftArr addObject:partNum];
        }
    }
    [self.session saveCurrentTemplateWithId:template.templateId version:template.version];
    partModelArray = [NSMutableArray arrayWithArray:template.virtualParts];
    
    for (int i = 0; i < partModelArray.count; i++) {
        DLYMiniVlogVirtualPart *part = partModelArray[i];
        if (i == 0) {
            part.prepareRecord = @"1";
        }else {
            part.prepareRecord = @"0";
        }
        part.recordStatus = @"0";
        
        DLYMiniVlogRecordType recordType = part.recordType;
        double startTime = 0;
        double stopTime = 0;
        double duration = 0;
        switch (recordType) {
            case DLYMiniVlogRecordTypeNormal:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = part.partTime;
                
                break;
            case DLYMiniVlogRecordTypeSlomo:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = [NSString stringWithFormat:@"%f",duration / SLOMOMULTI];
                
                break;
            case DLYMiniVlogRecordTypeTimelapse:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = [NSString stringWithFormat:@"%f",duration * 4];
                
                break;
            default:
                break;
        }
    }
    
    if (isExitDraft) {
        for (NSString *str in draftArr) {
            NSInteger num = [str integerValue];
            DLYMiniVlogVirtualPart *part = partModelArray[num];
            part.recordStatus = @"1";
        }
        
        for (DLYMiniVlogVirtualPart *part1 in partModelArray) {
            part1.prepareRecord = @"0";
        }
        
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogVirtualPart *part2 = partModelArray[i];
            if([part2.recordStatus isEqualToString:@"0"])
            {
                part2.prepareRecord = @"1";
                break;
            }
        }
    }
    
    typeModelArray = [[NSMutableArray alloc]init];
    //通用,美食,旅行,生活
    NSArray *typeNameArray = [self.session loadAllTemplateFile];
    for(int i = 0; i < typeNameArray.count; i ++)
    {
        DLYMiniVlogTemplate *template = [self.session loadTemplateWithTemplateName:typeNameArray[i]];
        [typeModelArray addObject:template];
    }
    
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

    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    [[DLYPhotoFilters sharedInstance] changeToName:template.filterName];
    [self.session saveCurrentTemplateWithId:template.templateId version:template.version];
    if (self.session.currentTemplate.previewBorderName) {
        self.previewMaskView.image = [UIImage imageNamed:self.session.currentTemplate.previewBorderName];
    }else{
        self.previewMaskView.image = nil;
    }
    partModelArray = [NSMutableArray arrayWithArray:template.virtualParts];
    
    for (int i = 0; i < partModelArray.count; i++) {
        DLYMiniVlogVirtualPart *part = partModelArray[i];
        if (i == 0) {
            part.prepareRecord = @"1";
        }else {
            part.prepareRecord = @"0";
        }
        part.recordStatus = @"0";
        
        DLYMiniVlogRecordType recordType = part.recordType;
        double startTime = 0;
        double stopTime = 0;
        double duration = 0;
        switch (recordType) {
            case DLYMiniVlogRecordTypeNormal:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = part.partTime;
                
                break;
            case DLYMiniVlogRecordTypeSlomo:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = [NSString stringWithFormat:@"%f",duration / SLOMOMULTI];
                
                break;
            case DLYMiniVlogRecordTypeTimelapse:
                startTime = [self getTimeWithString:part.dubStartTime]  / 1000;
                stopTime = [self getTimeWithString:part.dubStopTime] / 1000;
                duration = stopTime - startTime;
                part.partTime = [NSString stringWithFormat:@"%f",duration];
                part.duration = [NSString stringWithFormat:@"%f",duration * 4];
                
                break;
            default:
                break;
        }
    }
    //contentSize更新
    float episodeHeight = (self.backScrollView.height - (partModelArray.count - 1) * 2) / partModelArray.count;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * partModelArray.count + (partModelArray.count - 1) * 2);
    
    //模板数据
    typeModelArray = [[NSMutableArray alloc]init];
    NSArray *typeNameArray = [self.session loadAllTemplateFile];
    
    for(int i = 0; i < typeNameArray.count; i ++)
    {
        DLYMiniVlogTemplate *template = [self.session loadTemplateWithTemplateName:typeNameArray[i]];
        [typeModelArray addObject:template];
    }
    
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
    
    //OverlayView
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    overlayView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:overlayView];
    
    EAGLContext *eaglContext = [DLYContextManager sharedInstance].eaglContext;
    self.previewView = [[DLYPreviewView alloc] initWithFrame:SCREEN_RECT context:eaglContext];
    self.previewView.filter = [[DLYPhotoFilters sharedInstance] defaultFilter];
    
    self.imageTarget = self.previewView;
    self.previewView.coreImageContext = [DLYContextManager sharedInstance].ciContext;
    [overlayView insertSubview:self.previewView belowSubview:overlayView];
    
    self.previewStaticView = [[UIImageView alloc]initWithFrame:SCREEN_RECT];
    [overlayView addSubview:self.previewStaticView];
    self.previewBlurView = [[UIImageView alloc]initWithFrame:SCREEN_RECT];
    [overlayView addSubview:self.previewBlurView];
    self.previewMaskView = [[UIImageView alloc]initWithFrame:SCREEN_RECT];
    if (self.session.currentTemplate.previewBorderName) {
        self.previewMaskView.image = [UIImage imageNamed:self.session.currentTemplate.previewBorderName];
    }else{
        self.previewMaskView.image = nil;
    }
    [overlayView addSubview:self.previewMaskView];
    //通用button 选择场景button
    self.chooseScene = [[UIButton alloc]initWithFrame:CGRectMake(11, 16, 40, 40)];
    self.chooseScene.backgroundColor = RGBA(0, 0, 0, 0.4);
    [self.chooseScene addTarget:self action:@selector(onClickChooseScene:) forControlEvents:UIControlEventTouchUpInside];
    self.chooseScene.layer.cornerRadius = 20;
    self.chooseScene.clipsToBounds = YES;
    self.chooseScene.titleLabel.font = FONT_SYSTEM(14);
    [self.chooseScene setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    [self.view addSubview:self.chooseScene];
    
    self.chooseFilter = [[UIButton alloc]initWithFrame:CGRectMake(11, 94, 40, 40)];
    self.chooseFilter.backgroundColor = RGBA(0, 0, 0, 0.4);
    [self.chooseFilter addTarget:self action:@selector(onClickChooseFilter:) forControlEvents:UIControlEventTouchUpInside];
    self.chooseFilter.layer.cornerRadius = 20;
    self.chooseFilter.clipsToBounds = YES;
    self.chooseFilter.titleLabel.font = FONT_SYSTEM(14);
    [self.chooseFilter setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    [self.chooseFilter setImage:[UIImage imageWithIconName:IFNoFilter inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];

//    [self.view addSubview:self.chooseFilter];
    //显示场景的label 40
    self.chooseSceneLabel = [[UILabel alloc]initWithFrame:CGRectMake(6, self.chooseScene.bottom + 2, 50, 13)];
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    self.chooseSceneLabel.text = template.templateTitle;
    self.chooseSceneLabel.adjustsFontSizeToFitWidth = YES;
    self.chooseSceneLabel.font = FONT_SYSTEM(12);
    self.chooseSceneLabel.textColor = RGBA(255, 255, 255, 1);
    self.chooseSceneLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.chooseSceneLabel];
    
    self.chooseFilterLabel = [[UILabel alloc]initWithFrame:CGRectMake(6, self.chooseFilter.bottom + 2, 50, 13)];
    self.chooseFilterLabel.text = [[DLYPhotoFilters sharedInstance] currentDisplayFilterName];
    self.chooseFilterLabel.font = FONT_SYSTEM(12);
    self.chooseFilterLabel.textColor = RGBA(255, 255, 255, 1);
    self.chooseFilterLabel.textAlignment = NSTextAlignmentCenter;
//    [self.view addSubview:self.chooseFilterLabel];

    
    NSArray *typeNameArray = [self.session loadAllTemplateFile];
    for (int i = 0; i < typeNameArray.count; i ++) {
        if ([template.templateId isEqualToString:typeNameArray[i]]) {
            [self.chooseScene setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        }
    }
    
    //闪光
    self.flashButton = [[UIButton alloc]initWithFrame:CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40)];
    self.flashButton.layer.cornerRadius = 20;
    self.flashButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.flashButton.clipsToBounds = YES;
    [self.flashButton setImage:[UIImage imageWithIconName:IFFlashOff inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];

    [self.flashButton addTarget:self action:@selector(onClickFlashAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    //切换前置摄像头
    self.toggleCameraBtn = [[UIButton alloc]initWithFrame:CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40)];
    self.toggleCameraBtn.layer.cornerRadius = 20;
    self.toggleCameraBtn.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.toggleCameraBtn.clipsToBounds = YES;
    [self.toggleCameraBtn setImage:[UIImage imageWithIconName:IFToggleLens inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.toggleCameraBtn addTarget:self action:@selector(toggleCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleCameraBtn];
    
    //右边的view
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT)];
    self.backView.backgroundColor = RGBA(0, 0, 0, 0.7);
    [self.view addSubview:self.backView];
    
    //版本页面
    //    self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, self.backView.height - 20, 50, 20)];
    //    self.versionLabel.textColor = [UIColor whiteColor];
    //    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    //    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    //    NSString *buildVersion = [infoDic objectForKey:@"CFBundleVersion"];
    //    NSString *labelText = [NSString stringWithFormat:@"%@(%@)", appVersion,buildVersion];
    //    self.versionLabel.text = labelText;
    //    self.versionLabel.font = FONT_SYSTEM(12);
    //    [self.backView addSubview:self.versionLabel];
    
    //拍摄按钮
    self.recordBtn = [[UIButton alloc]initWithFrame:CGRectMake(43 * SCALE_WIDTH, 0, 60 * SCALE_WIDTH, 60 * SCALE_WIDTH)];
    self.recordBtn.centerY = self.backView.centerY;
    [self.recordBtn setImage:[UIImage imageWithIconName:IFRecord inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
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
    [self.deleteButton setImage:[UIImage imageWithIconName:IFDeleteAll inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(onClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteButton];
    
    //片段view
    self.backScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(103 * SCALE_WIDTH, 15 * SCALE_HEIGHT, 53, SCREEN_HEIGHT - 30  * SCALE_HEIGHT)];
    self.backScrollView.showsVerticalScrollIndicator = NO;
    self.backScrollView.showsHorizontalScrollIndicator = NO;
    self.backScrollView.bounces = NO;
    [self.backView addSubview:self.backScrollView];
    float episodeHeight = (self.backScrollView.height - (partModelArray.count - 1) * 2) / partModelArray.count;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * partModelArray.count + (partModelArray.count - 1) * 2);
    _prepareShootTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(prepareShootAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_prepareShootTimer forMode:NSRunLoopCommonModes];
    [_prepareShootTimer setFireDate:[NSDate distantFuture]];
    
    //右侧编辑页面
    self.playView = [[UIView alloc]initWithFrame:CGRectMake(43 * SCALE_WIDTH, 0, 60 * SCALE_WIDTH, SCREEN_HEIGHT)];
    self.playView.hidden = YES;
    [self.backView addSubview:self.playView];
    //右侧：播放某个片段的button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60 * SCALE_WIDTH, (SCREEN_HEIGHT - 152)/2, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.playButton addTarget:self action:@selector(onClickPlayPartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setImage:[UIImage imageWithIconName:IFPlayVideo inFont:ICONFONT size:15 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.playButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.playButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.playButton.layer.borderWidth = 1;
    [self.playView addSubview:self.playButton];
    //右侧：删除某个片段的button
    self.deletePartButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60* SCALE_WIDTH, SCREEN_HEIGHT/2 + 76 - 60* SCALE_WIDTH, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
    [self.deletePartButton addTarget:self action:@selector(onClickDeletePartVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.deletePartButton setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.deletePartButton.layer.cornerRadius = 30* SCALE_WIDTH;
    self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
    self.deletePartButton.layer.borderWidth = 1;
    [self.playView addSubview:self.deletePartButton];
    
    self.shootGuide = [[UILabel alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 49, SCREEN_WIDTH - 91 - 180 * SCALE_WIDTH, 30)];
    if (self.newState == 1) {
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 51;
    }else {
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 180 * SCALE_WIDTH;
    }
    self.shootGuide.backgroundColor = RGBA(0, 0, 0, 0.7);
    self.shootGuide.textColor = RGB(255, 255, 255);
    self.shootGuide.font = FONT_SYSTEM(14);
    self.shootGuide.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.shootGuide];
    [self.view bringSubviewToFront:self.shootGuide];
    
    //创建片段界面
    [self createPartView];
    //创建场景页面
    [self createSceneView];
    [self createFilterView];
    [self createVideoView];
    [self.view addSubview:[self shootView]];
}
#pragma mark - 初始化相机
- (void)initializationRecorder {
    
    self.AVEngine = [[DLYAVEngine alloc] initWithPreviewView:self.previewView];
    self.AVEngine.delegate = self;
}
-(void)imageWithImageTarget:(CIImage *)sourceImage{
    [self.imageTarget setImage:sourceImage];
}
#pragma mark -触屏自动调整曝光-
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    if (touch.view != self.backView && touch.view != self.sceneView && touch.view != self.playView
        && touch.view != self.filterView&& touch.view != self.filterContentView)
    {
        CGPoint point = [touch locationInView:self.previewView];
//        CGPoint cameraPoint = [self.AVEngine.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
        [self.AVEngine focusContinuousWithPoint:point];
        [self setFocusCursorWithPoint:point];
    }
}
- (void)setFocusCursorWithPoint:(CGPoint)point {
    
    CGPoint changePoint = point;
    if (self.newState == 1 &&  self.AVEngine.cameraPosition == DLYAVEngineCapturePositionTypeFront) {//右手 + 前置
        changePoint = CGPointMake(point.x, SCREEN_HEIGHT - point.y);
    }
    
    if (self.newState == 2 && self.AVEngine.cameraPosition == DLYAVEngineCapturePositionTypeBack) {//左手 + 后置
        changePoint = CGPointMake(SCREEN_WIDTH - point.x, SCREEN_HEIGHT - point.y);
    }
    
    if (self.newState == 2 && self.AVEngine.cameraPosition == DLYAVEngineCapturePositionTypeFront) {//左手 + 前置
        changePoint = CGPointMake(SCREEN_WIDTH - point.x,point.y);
    }
    self.focusCursorImageView.center = changePoint;
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
                                   AVVideoCodecTypeH264, AVVideoCodecKey,
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
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                }];
                DLYLog(@"comp completed !");
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
                    DLYLog(@"FAIL");
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

#pragma mark ==== 左手模式重新布局
//设备方向改变后调用的方法
//后面改变的状态
- (void)deviceChangeAndHomeOnTheLeft {//左手模式
    
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        [self deviceChangeAndHomeOnTheLeftNewLayout];
        DLYLog(@"首页左转");
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
    if (![self.AVEngine isRecording]) {
        [self resetPreviewViewTransform];
        self.AVEngine.orientation = UIDeviceOrientationLandscapeRight;
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeRight;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }else{
        DLYLog(@"录制过程中不再重设录制正方向");
    }
}
//home在右 初始状态
- (void)deviceChangeAndHomeOnTheRight {//右手模式
    
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        [self deviceChangeAndHomeOnTheRightNewLayout];
        DLYLog(@"首页右转");
        [UIView animateWithDuration:0.5 animations:^{
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }];
    }
    if (![self.AVEngine isRecording]) {
        [self resetPreviewViewTransform];
        self.AVEngine.orientation = UIDeviceOrientationLandscapeLeft;

        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }else{
        DLYLog(@"录制过程中不再重设录制正方向");
    }
}
- (void)resetPreviewViewTransform{
    if (self.AVEngine.cameraPosition == DLYAVEngineCapturePositionTypeBack) {
        if (self.newState == 1) {
            self.previewView.transform = CGAffineTransformIdentity;
        }else{
            self.previewView.transform = CGAffineTransformMakeRotation(M_PI);
        }
        
    }else{
        CGAffineTransform flipLR = CGAffineTransformMakeScale(-1.0, 1.0);
        if (self.newState == 1) {
            self.previewView.transform = CGAffineTransformRotate(flipLR, M_PI);
        }else{
            self.previewView.transform = flipLR;
        }
    }
    
}
- (void)deviceChangeAndHomeOnTheLeftNewLayout {
    [self createLeftPartView];
    
    if (!self.playView.isHidden && self.playView) {
        UIButton *button = (UIButton *)[self.view viewWithTag:cursorTag];
        selectPartTag = cursorTag;
        //点击哪个item，光标移动到当前item
        prepareTag = button.tag;
        
        for (DLYMiniVlogVirtualPart *part in partModelArray) {
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
        
        for (DLYMiniVlogVirtualPart *part in partModelArray) {
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
            self.warningIcon.frame = CGRectMake(SCREEN_WIDTH - 60, SCREEN_HEIGHT - 54, 32, 32);
        }
    }
    if (!self.shootGuide.isHidden && self.shootGuide) {
        if (num == 0) {
            self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 51;
        }else {
            self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 180 * SCALE_WIDTH;
        }
        if (!self.shootView.isHidden && self.shootView) {
            self.shootGuide.centerX = _shootView.centerX;
        }
    }
    if (!self.titleView.isHidden && self.titleView) {
        if (num == 0) {
            self.titleView.frame = CGRectMake(SCREEN_WIDTH - 190, 20, 180, 30);
        }else {
            self.titleView.frame = CGRectMake(10, 20, 180, 30);
        }
    }
    
    if (!self.timeView.isHidden && self.timeView) {
        if (num == 0) {
            self.timeView.frame = CGRectMake(SCREEN_WIDTH - 70, 0, 60, 60);
            self.timeView.centerY = self.shootView.centerY;
            self.cancelButton.centerX = self.timeView.centerX;
        }else {
            self.timeView.frame = CGRectMake(10, 0, 60, 60);
            self.timeView.centerY = self.shootView.centerY;
            self.cancelButton.centerX = self.timeView.centerX;
        }
    }
    
    if (!self.chooseScene.isHidden && self.chooseScene) {
        if (num == 0) {
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
        }else {
            self.chooseScene.frame = CGRectMake(SCREEN_WIDTH - 51, 16, 40, 40);
        }
    }
    if (!self.chooseSceneLabel.isHidden && self.chooseSceneLabel) {
        if (num == 0) {
            self.chooseSceneLabel.frame = CGRectMake(6, self.chooseScene.bottom + 2, 50, 13);
        }else {
            self.chooseSceneLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseScene.bottom + 2, 50, 13);
        }
    }
    
    if (!self.chooseFilter.isHidden && self.chooseFilter) {
        if (num == 0) {
            self.chooseFilter.frame = CGRectMake(11, 94, 40, 40);
        }else {
            self.chooseFilter.frame = CGRectMake(SCREEN_WIDTH - 51, 94, 40, 40);
        }
    }
    if (!self.chooseFilterLabel.isHidden && self.chooseFilterLabel) {
        if (num == 0) {
            self.chooseFilterLabel.frame = CGRectMake(6, self.chooseFilter.bottom + 2, 50, 13);
        }else {
            self.chooseFilterLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseFilter.bottom + 2, 50, 13);
        }
    }
    if (!self.filterView.isHidden && self.filterView) {
        if (num == 0) {
            self.filterView.frame = CGRectMake(61, 10, 120, SCREEN_HEIGHT-20);
        }else {
            self.filterView.frame = CGRectMake(SCREEN_WIDTH-61-120, 10, 120, SCREEN_HEIGHT-20);
        }
    }
    if (!self.toggleCameraBtn.isHidden && self.toggleCameraBtn) {
        if (num == 0) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
        }else {
            self.toggleCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 51, 40, 40);
        }
    }
    if (!self.flashButton.isHidden && self.flashButton) {
        if (num == 0) {
            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
        }else {
            self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
        }
    }
    
    if (!self.deleteButton.isHidden && self.deleteButton) {
        if (num == 0) {
            self.deleteButton.frame = CGRectMake(self.view.centerX - 121, self.view.centerY - 30, 60, 60);
        }else {
            self.deleteButton.center = self.view.center;
        }
    }
    if (!self.nextButton.isHidden && self.nextButton) {
        if (num == 0) {
            self.nextButton.center = self.view.center;
        }else {
            self.nextButton.frame = CGRectMake(self.view.centerX + 61, self.view.centerY - 30, 60, 60);
        }
    }
    //    if (!self.versionLabel.isHidden && self.versionLabel) {
    //        if (num == 0) {
    //            self.versionLabel.frame = CGRectMake(2, self.backView.height - 20, 50, 20);
    //        }else {
    //            self.versionLabel.frame = CGRectMake(self.backView.width - 52, self.backView.height - 20, 50, 20);
    //        }
    //    }
    
    if (!self.normalBubble.isHidden && self.normalBubble) {
        self.normalBubble.flipState = self.newState;
    }
    if (!self.allBubble.isHidden && self.allBubble) {
        self.allBubble.deleteState = self.newState;
    }
    if (!self.partBubble.isHidden && self.partBubble) {
        self.partBubble.flipState = self.newState;
    }
    if (!self.nextStepBubble.isHidden && self.nextStepBubble) {
        self.nextStepBubble.nextStepState = self.newState;
    }
}

#pragma mark ==== button点击事件
//补光灯开关
- (void)onClickFlashAction {
    [DLYUserTrack recordAndEventKey:@"FlashBtn"];
    self.flashButton.selected = !self.flashButton.selected;
    if (self.flashButton.selected == YES) { //打开闪光灯
        [self.flashButton setImage:[UIImage imageWithIconName:IFFlashOn inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [self.AVEngine switchFlashMode:YES];
    }else{//关闭闪光灯
        [self.flashButton setImage:[UIImage imageWithIconName:IFFlashOff inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [self.AVEngine switchFlashMode:NO];
    }
}
#pragma mark ==== 切换摄像头
- (void)toggleCameraAction {
    
    [DLYUserTrack recordAndEventKey:@"ToggleCamera"];
    
    if (isSlomoCamera) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showSlomoCameraPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSlomoCameraPopup"];
            self.normalBubble = [DLYPopupMenu showRelyOnView:self.toggleCameraBtn titles:@[@"慢镜头不能使用前置摄像头"] icons:nil menuWidth:120 withState:self.newState delegate:self];
            self.normalBubble.showMaskAlpha = 1;
            self.normalBubble.flipState = self.newState;
        }
        return;
    }

    [self.AVEngine switchCameras];
    [self resetPreviewViewTransform];

//    if (self.AVEngine.cameraPosition == DLYAVEngineCapturePositionTypeFront) {
//    }
//    self.toggleCameraBtn.selected = !self.toggleCameraBtn.selected;
//    if (self.toggleCameraBtn.selected) {
//        [self.AVEngine changeCameraInputDeviceisFront:YES];
//
//        self.flashButton.hidden = YES;
//        if (self.flashButton.selected) {
//            self.flashButton.selected = NO;
//        }
//        isFront = YES;
//    }else{
//        [self.AVEngine changeCameraInputDeviceisFront:NO];
//        if (self.newState == 1) {
//            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
//        }else {
//            self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
//        }
//        self.flashButton.hidden = NO;
//        isFront = NO;
//    }
}
//选择场景
- (void)onClickChooseScene:(UIButton *)sender {
    [DLYUserTrack recordAndEventKey:@"ChooseScene"];
    [self showChooseSceneView];
}
- (void)onClickChooseFilter:(UIButton *)sender{
    [DLYUserTrack recordAndEventKey:@"ChooseFilter"];
    [self showChooseFilterView];
}
//显示模板页面
- (void)showChooseSceneView {
    
    [UIView animateWithDuration:0.1f animations:^{
        self.chooseScene.hidden = YES;
        self.chooseFilter.hidden = YES;
        self.toggleCameraBtn.hidden = YES;
        self.flashButton.hidden = YES;
        self.chooseSceneLabel.hidden = YES;
        self.chooseFilterLabel.hidden = YES;
        self.backView.hidden = YES;
        self.filterContentView.hidden = YES;

        [self.partBubble dismiss];
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
    } completion:^(BOOL finished) {
        [DLYUserTrack recordAndEventKey:@"ChooseSceneViewStart"];
        [DLYUserTrack beginRecordPageViewWith:@"ChooseSceneView"];
        self.sceneView.hidden = NO;
        self.sceneView.alpha = 1;
        //气泡
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showSeeRushPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSeeRushPopup"];
            DLYPopupMenu *videoBubble = [DLYPopupMenu showRelyOnView:self.seeRush titles:@[@"观看样片"] icons:nil menuWidth:120 delegate:self];
            videoBubble.showMaskAlpha = 1;
        }
    }];

}
//显示选择filter页面
- (void)showChooseFilterView {
    
    [UIView animateWithDuration:0.1f animations:^{
//        self.chooseScene.hidden = YES;
//        self.chooseFilter.hidden = YES;
//        self.toggleCameraBtn.hidden = YES;
//        self.flashButton.hidden = YES;
//        self.chooseSceneLabel.hidden = YES;
//        self.chooseFilterLabel.hidden = YES;
//        self.backView.hidden = YES;
        [self.partBubble dismiss];
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
    } completion:^(BOOL finished) {
//        [DLYUserTrack recordAndEventKey:@"ChooseSceneViewStart"];
//        [DLYUserTrack beginRecordPageViewWith:@"ChooseSceneView"];
        self.filterContentView.hidden = NO;
        if (self.newState == 1) {
            self.filterView.frame = CGRectMake(61, 10, 120, SCREEN_HEIGHT-20);
        }else {
            self.filterView.frame = CGRectMake(SCREEN_WIDTH-61-120, 10, 120, SCREEN_HEIGHT-20);
        }
        self.filterView.hidden = NO;

        //气泡
//        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showSeeRushPopup"]){
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSeeRushPopup"];
//            DLYPopupMenu *videoBubble = [DLYPopupMenu showRelyOnView:self.seeRush titles:@[@"观看样片"] icons:nil menuWidth:120 delegate:self];
//            videoBubble.showMaskAlpha = 1;
//        }
    }];
    
}

//拍摄视频按键
- (void)startRecordBtnAction {
    
    [DLYUserTrack recordAndEventKey:@"StartRecord"];
    
    if (self.newState == 1) {
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }else {
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeRight;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    
    NSInteger i = selectPartTag - 10000;
    DLYMiniVlogVirtualPart *part = partModelArray[i - 1];
    shootNum = 0.0;

    [self.AVEngine startRecordingWithPart:part];
    
    DLYLog(@"计时器开始计时 :%@",[self getCurrentTime_MS]);
    
    // change UI
    [self.shootView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self createShootView];
    for (DLYMiniVlogVirtualPart *part in partModelArray) {
        if([part.prepareRecord isEqualToString:@"1"])
        {
            if(part.recordType != DLYMiniVlogRecordTypeNormal)
            {
                if (self.newState == 1) {
                    self.warningIcon.frame = CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32);
                }else {
                    self.warningIcon.frame = CGRectMake(SCREEN_WIDTH - 60, SCREEN_HEIGHT - 54, 32, 32);
                }
                self.warningIcon.hidden = NO;
            }else
            {
                if (part.BGMVolume == 100) {
                    if (self.newState == 1) {
                        self.warningIcon.frame = CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32);
                    }else {
                        self.warningIcon.frame = CGRectMake(SCREEN_WIDTH - 60, SCREEN_HEIGHT - 54, 32, 32);
                    }
                    self.warningIcon.hidden = NO;
                }else {
                    self.warningIcon.hidden = YES;
                }
            }
        }
    }
    
    [UIView animateWithDuration:0.5f animations:^{
        self.chooseScene.hidden = YES;
        self.chooseSceneLabel.hidden = YES;
        self.chooseFilter.hidden = YES;
        self.chooseFilterLabel.hidden = YES;
        self.toggleCameraBtn.hidden = YES;
        self.flashButton.hidden = YES;
        if (self.newState == 1) {
            self.backView.frame = CGRectMake(SCREEN_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
        }else {
            self.backView.frame = CGRectMake(-180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
        }
    } completion:^(BOOL finished) {
        self.backView.hidden = YES;
        self.shootView.hidden = NO;
        self.shootView.alpha = 1;
    }];
}

- (void) statutUpdateWithClockTick:(double)count{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self.timeNumber.text isEqualToString:@"1"]) {
            self.timeNumber.text = [NSString stringWithFormat:@"%d",(int)count];
            if (shootNum < count) {
                _progressView.animationTime = count;
                shootNum = count;
            }
        }
    });
}

- (void)finishedRecording {
    NSInteger partNumber = selectPartTag - 10000;
    DLYMiniVlogVirtualPart *part = partModelArray[partNumber - 1];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cancelButton.hidden = YES;
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogVirtualPart *part1 = partModelArray[i];
            part1.prepareRecord = @"0";
        }
        part.prepareRecord = @"0";
        part.recordStatus = @"1";
        
        NSInteger n = 0;
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogVirtualPart *part2 = partModelArray[i];
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
        self.completeButton.hidden = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.completeButton.hidden = YES;
        });
    });
}

//跳转至下一个界面按键
- (void)onClickNextStep:(UIButton *)sender {
    [DLYUserTrack recordAndEventKey:@"NextStep"];
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
    [DLYUserTrack recordAndEventKey:@"DeleteAll"];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"deleteAllPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deleteAllPopup"];
        self.allBubble = [DLYPopupMenu showDeleteOnView:sender titles:@[@"点击删除全部片段"] icons:nil menuWidth:120 withState:self.newState delegate:self];
        self.allBubble.showMaskAlpha = 0;
        self.allBubble.deleteState = self.newState;
        self.allBubble.dismissOnTouchOutside = NO;
        self.allBubble.dismissOnSelected = NO;
    }
    if (sender.selected == NO) {
        self.deleteButton.backgroundColor = RGBA(255, 0, 0, 1);
    }else {
        [self.allBubble dismiss];
        if (self.allBubble) {
            [self.allBubble removeFromSuperview];
            self.allBubble = nil;
        }
        sender.backgroundColor = RGBA(0, 0, 0, 0.4);
        [self.resource removeCurrentAllPartFromDocument];
        //数组初始化，view布局
        if (!self.playView.isHidden && self.playView) {
            [self.partBubble dismiss];
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
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
    [DLYUserTrack recordAndEventKey:@"PlayPart"];
    NSInteger partNum = selectPartTag - 10000 - 1;
    DLYPlayVideoViewController *playVC = [[DLYPlayVideoViewController alloc] init];
    playVC.playUrl = [self.resource getVirtualPartUrlWithPartNum:partNum];
    playVC.isAll = NO;
    playVC.beforeState = self.newState;
    playVC.previewBorderName = self.session.currentTemplate.previewBorderName;
    self.isPlayer = YES;
    [self hideBubbleWhenPush];
    [self.navigationController pushViewController:playVC animated:YES];
    
}
//删除某个片段
- (void)onClickDeletePartVideo:(UIButton *)sender {
    [DLYUserTrack recordAndEventKey:@"DeletePart"];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"deletePartPopup"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deletePartPopup"];
        self.partBubble = [DLYPopupMenu showRelyOnView:sender titles:@[@"点击删除该片段"] icons:nil menuWidth:120 withState:self.newState delegate:self];
        self.partBubble.showMaskAlpha = 0;
        self.partBubble.flipState = self.newState;
        self.partBubble.dismissOnTouchOutside = NO;
        self.partBubble.dismissOnSelected = NO;
    }
    if (sender.selected == NO) {
        [sender setImage:[UIImage imageWithIconName:IFDeleteAll inFont:ICONFONT size:24 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
        sender.layer.borderColor = RGBA(255, 0, 0, 1).CGColor;
    }else {
        [self.partBubble dismiss];
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
        [sender setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        sender.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        NSInteger partNum = selectPartTag - 10000 - 1;
        [self.resource removePartWithPartNumFormTemp:partNum];
        [self.resource removePartWithPartNumFromDocument:partNum];
        [self.resource removeVirtualPartWithPartNumFromDocument:partNum];
        if  (self.AVEngine.currentPart.partsInfo.count>1){
            [self.resource removeCurrentAllPartFromDocument];
        }
        [self deleteSelectPartVideo];
    }
    sender.selected = !sender.selected;
}

- (void)hideBubbleWhenPush {
    [self.partBubble dismiss];
    if (self.partBubble) {
        [self.partBubble removeFromSuperview];
        self.partBubble = nil;
    }
    [self.allBubble dismiss];
    if (self.allBubble) {
        [self.allBubble removeFromSuperview];
        self.allBubble = nil;
    }
}

//取消选择场景
- (void)onClickCancelSelect:(UIButton *)sender {
    [self cancelChooseSceneView];
}

- (void)cancelChooseSceneView {
    [DLYUserTrack recordAndEventKey:@"CancelSelect"];
    [UIView animateWithDuration:0.5f animations:^{
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(6, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(11, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(11, self.chooseFilter.bottom + 2, 40, 40);

        }else {
            self.toggleCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(SCREEN_WIDTH - 51, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(SCREEN_WIDTH - 51, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseFilter.bottom + 2, 50, 13);

        }
        self.toggleCameraBtn.hidden = NO;
        self.chooseScene.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.chooseFilter.hidden = NO;
        self.chooseFilterLabel.hidden = NO;


        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
            }else {
                self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
            }
            self.flashButton.hidden = NO;
        }

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

- (void)showVideoView {
    self.videoView.hidden = NO;
    [DLYUserTrack recordAndEventKey:@"ChooseVideoViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"ChooseVideoView"];
}

- (void)hideVideoView {
    [DLYUserTrack recordAndEventKey:@"BackVideoView"];
    self.videoView.hidden = YES;
    [DLYUserTrack recordAndEventKey:@"ChooseVideoViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"ChooseVideoView"];
}
- (void)hiddenFilterContentView{
//    [DLYUserTrack recordAndEventKey:@"BackVideoView"];
    self.filterContentView.hidden = YES;
    self.filterView.hidden = YES;
    
//    [DLYUserTrack recordAndEventKey:@"ChooseVideoViewEnd"];
//    [DLYUserTrack endRecordPageViewWith:@"ChooseVideoView"];
}
- (void)changeVideoToPlay:(UIButton *)sender {
    
    NSInteger num = sender.tag - 600;
    //url放在这里
    DLYMiniVlogTemplate *template = videoArray[num];
    [DLYUserTrack recordAndEventKey:@"ChoosePlayVideo" andDescribeStr:template.templateTitle];
    
    NSArray *urlNameArr = [template.sampleVideoName componentsSeparatedByString:@"/"];
    NSString *nameStr = [urlNameArr lastObject];
    NSString *videoName = [nameStr stringByReplacingOccurrencesOfString:@".mp4" withString:@""];
    NSString *videoUrl = template.sampleVideoName;
    
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
    [DLYUserTrack recordAndEventKey:@"CancelRecord"];
    [self.AVEngine cancelRecording];
    NSInteger partNum = selectPartTag - 10000 - 1;
    [self.resource removePartWithPartNumFormTemp:partNum];
    
    if (self.newState == 1) {
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 51;
    }else {
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 180 * SCALE_WIDTH;
    }
    if (self.newState == 1) {
        self.backView.frame = CGRectMake(SCREEN_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
    }else {
        self.backView.frame = CGRectMake(-180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
    }
    [UIView animateWithDuration:0.5f animations:^{
        self.progressView.hidden = YES;
        self.timeNumber.hidden = YES;
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(6, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(11, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(6, self.chooseFilter.bottom + 2, 50, 13);
            self.backView.frame = CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);

        }else {
            self.toggleCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(SCREEN_WIDTH - 51, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(SCREEN_WIDTH - 51, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseFilter.bottom + 2, 50, 13);
            self.backView.frame = CGRectMake(0, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);

        }
        self.toggleCameraBtn.hidden = NO;
        self.chooseScene.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.chooseFilter.hidden = NO;
        self.chooseFilterLabel.hidden = NO;
        self.backView.hidden = NO;
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
            }else {
                self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
            }
            self.flashButton.hidden = NO;
        }
        self.shootView.alpha = 0;
        self.shootView.hidden = YES;
    } completion:^(BOOL finished) {
    }];
    
    if (self.newState == 1) {
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }else {
        self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeRight;
        self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
}
//删除某个片段的具体操作
- (void)deleteSelectPartVideo {
    
    NSInteger i = selectPartTag - 10000;
    
    DLYMiniVlogVirtualPart *part = partModelArray[i-1];
    
    [UIView animateWithDuration:0.5f animations:^{
        
        self.playView.hidden = YES;
        self.recordBtn.hidden = NO;
    } completion:^(BOOL finished) {
        
    }];
    
    for(int i = 0; i < partModelArray.count; i++)
    {
        DLYMiniVlogVirtualPart *part1 = partModelArray[i];
        part1.prepareRecord = @"0";
    }
    part.prepareRecord = @"0";
    part.recordStatus = @"0";
    
    NSInteger n = 0;
    for(int i = 0; i < partModelArray.count; i++)
    {
        DLYMiniVlogVirtualPart *part2 = partModelArray[i];
        
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
    for (DLYMiniVlogVirtualPart *part3 in partModelArray) {
        if ([part3.recordStatus isEqualToString:@"0"]) {
            self.nextButton.hidden = YES;
            [self.allBubble dismiss];
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
    
    self.recordBtn.frame = CGRectMake(43 * SCALE_WIDTH, 0, 60*SCALE_WIDTH, 60 * SCALE_WIDTH);
    self.recordBtn.centerY = self.backView.centerY;
    self.playView.frame = CGRectMake(43 * SCALE_WIDTH, 0, 60 * SCALE_WIDTH, SCREEN_HEIGHT);
    self.backScrollView.frame = CGRectMake(103 * SCALE_WIDTH, 15 * SCALE_HEIGHT, 53, SCREEN_HEIGHT - 30  * SCALE_HEIGHT);
    self.backView.frame = CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HEIGHT - 30  * SCALE_HEIGHT - (partModelArray.count - 1) * 2)/ partModelArray.count;
    
    if(SCREEN_HEIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - (partModelArray.count - 1) * 2) / partModelArray.count;
    }
    [self.toggleCameraBtn setImage:[UIImage imageWithIconName:IFToggleLens inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    isSlomoCamera = NO;
    BOOL isAllPart = YES;
    for(int i = 1; i <= partModelArray.count; i ++)
    {
        DLYMiniVlogVirtualPart *part = partModelArray[i - 1];
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
                icon.image = [UIImage imageWithIconName:IFFastLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
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
                icon.image = [UIImage imageWithIconName:IFSlowLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
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
                    icon.image = [UIImage imageWithIconName:IFFastLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                    
                    //判断切换摄像头
                    if (self.toggleCameraBtn.selected) {
                        [self.AVEngine changeCameraInputDeviceisFront:NO];
                        self.toggleCameraBtn.selected = NO;
                        isFront = NO;
                        if (self.newState == 1) {
                            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                        }else {
                            self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
                        }
                        self.flashButton.hidden = NO;
                    }
                    [self.toggleCameraBtn setImage:[UIImage imageWithIconName:IFStopToggle inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
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
                    icon.image = [UIImage imageWithIconName:IFSlowLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }
            }
        }
        
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
   // [self changeRecordType];
    if (isAllPart) {
        [self showPlayView];
    }
    [self updateShootGuide];
    
}

- (void)changeRecordType {
    NSInteger partNumber = selectPartTag - 10000;
    DLYMiniVlogVirtualPart *part = partModelArray[partNumber - 1];
    //设置当前片段录制格式
    [self.AVEngine switchRecordFormatWithRecordType:part.recordType];
}

- (void)showPlayView {
    //光标
    prepareTag = 10001;
    oldPrepareTag = prepareTag;
    prepareAlpha = 1;
    [_prepareShootTimer setFireDate:[NSDate distantPast]];
    
    if (self.playView.isHidden && self.playView) {
        selectPartTag = 10001;
        cursorTag = selectPartTag;
        self.playView.hidden = NO;
    }
}

- (void)updateShootGuide {
    
    NSInteger i = selectPartTag - 10000;
    DLYMiniVlogVirtualPart *part = partModelArray[i-1];
    self.shootGuide.text = part.shootGuide;
    if ([self.shootGuide.text isEqualToString:@""]||!self.shootGuide.text) {
        self.shootGuide.hidden = YES;
    }else{
        self.shootGuide.hidden = NO;
    }
}

- (void)createLeftPartView {
    
    CGFloat backWidth = self.backView.width;
    self.recordBtn.frame = CGRectMake(backWidth - 103 * SCALE_WIDTH, 0, 60*SCALE_WIDTH, 60 * SCALE_WIDTH);
    self.recordBtn.centerY = self.backView.centerY;
    self.playView.frame = CGRectMake(backWidth - 103 * SCALE_WIDTH, 0, 60 * SCALE_WIDTH, SCREEN_HEIGHT);
    self.backScrollView.frame = CGRectMake(backWidth - 103 * SCALE_WIDTH - 53, 15 * SCALE_HEIGHT, 53, SCREEN_HEIGHT - 30  * SCALE_HEIGHT);
    self.backView.frame = CGRectMake(0, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
    
    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HEIGHT - 30  * SCALE_HEIGHT - (partModelArray.count - 1) * 2)/ partModelArray.count;
    
    if(SCREEN_HEIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - (partModelArray.count - 1) * 2) / partModelArray.count;
    }
    [self.toggleCameraBtn setImage:[UIImage imageWithIconName:IFToggleLens inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    isSlomoCamera = NO;
    BOOL isAllPart = YES;
    for(int i = 1; i <= partModelArray.count; i ++)
    {
        DLYMiniVlogVirtualPart *part = partModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(0, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        button.tag = 10000 + i;
        UIEdgeInsets edgeInsets = {0, -5, 0, -43};
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
                timeLabel.frame = CGRectMake(button.right + 4, 0, timeLabel.width, timeLabel.height);
                timeLabel.centerY = button.centerY;
                [self.backScrollView addSubview:timeLabel];
                
            }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
            {//慢动作
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(button.right + 4, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentLeft;
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
                icon.image = [UIImage imageWithIconName:IFFastLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                [itemView addSubview:icon];
            }else
            {//延时
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(button.right + 4, 0, 39, 28)];
                itemView.centerY = button.centerY;
                [self.backScrollView addSubview:itemView];
                
                UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                timeLabel.textAlignment = NSTextAlignmentLeft;
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
                icon.image = [UIImage imageWithIconName:IFSlowLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
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
                UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(button.right + 4, 0, 39, 28)];
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
                    timeLabel.frame = CGRectMake(0, (itemView.height - timeLabel.height) / 2, timeLabel.width, timeLabel.height);
                    [itemView addSubview:timeLabel];
                    
                }else if(part.recordType == DLYMiniVlogRecordTypeSlomo)
                {//慢进
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentLeft;
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
                    icon.image = [UIImage imageWithIconName:IFFastLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                    
                    //判断切换摄像头
                    if (self.toggleCameraBtn.selected) {
                        [self.AVEngine changeCameraInputDeviceisFront:NO];
                        self.toggleCameraBtn.selected = NO;
                        isFront = NO;
                        if (self.newState == 1) {
                            self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
                        }else {
                            self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
                        }
                        self.flashButton.hidden = NO;
                    }
                    [self.toggleCameraBtn setImage:[UIImage imageWithIconName:IFStopToggle inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
                    isSlomoCamera = YES;
                }else
                {//延时
                    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentLeft;
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
                    icon.image = [UIImage imageWithIconName:IFSlowLens inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [itemView addSubview:icon];
                }
            }
        }
        
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
   // [self changeRecordType];
    if (isAllPart) {
        [self showPlayView];
    }
    [self updateShootGuide];
}

- (void)prepareShootAction {
    
    if (oldPrepareTag != prepareTag) {
        DLYMiniVlogVirtualPart *part = partModelArray[oldPrepareTag - 10001];
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
            button.alpha = 0.01;
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
- (UIImage *)blurUIView:(UIView *)view {
    UIGraphicsBeginImageContext(view.frame.size);
    [view drawViewHierarchyInRect:view.frame afterScreenUpdates:NO];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return  snapshot;
    return [snapshot applyLightEffect];
}
-(void)blurDismissAnimation{
    self.previewView.alpha = 0;
    self.previewView.hidden = NO;
    self.previewStaticView.image = nil;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.previewBlurView.alpha = 0.1;
        self.previewView.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished) {
            self.previewBlurView.image = nil;
        }
        
    }];
}
#pragma mark ==== 每个拍摄片段的点击事件
- (void)vedioEpisodeClick:(UIButton *)sender {
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    [self.previewStaticView.layer removeAllAnimations];
    [self.previewBlurView.layer removeAllAnimations];
    
    UIButton * button = (UIButton *)sender;
    NSInteger i = button.tag - 10000;
    selectPartTag = button.tag;
    DLYMiniVlogVirtualPart *part = partModelArray[i-1];
    if (self.previewBlurView.image==nil) {
        self.previewView.hidden = YES;
        UIImage *originalImage = [self blurUIView:self.previewView];
        self.previewStaticView.alpha = 1;
        self.previewStaticView.image = originalImage;
        self.previewBlurView.alpha = 0;
        self.previewBlurView.image = [originalImage applyLightEffect];
        [UIView animateWithDuration:0.5 animations:^{
            self.previewBlurView.alpha = 1;
            self.previewStaticView.alpha = 0;
        }];
    }


    //设置当前片段录制格式
    [self.AVEngine switchRecordFormatWithRecordType:part.recordType];
    
    [self performSelector:@selector(blurDismissAnimation)
               withObject:self
               afterDelay:1.f];

    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    NSString *partStr = [NSString stringWithFormat:@"第%ld段", (long)i];
    [DLYUserTrack recordAndEventKey:@"ChooseRecordPart" andDescribeStr:template.templateTitle andPartNum:partStr];
    //点击哪个item，光标移动到当前item
    prepareTag = button.tag;
    
    if([part.recordStatus isEqualToString:@"1"])
    {//说明时已拍摄片段
        for (DLYMiniVlogVirtualPart *part in partModelArray) {
            if ([part.prepareRecord isEqualToString:@"1"]) {
                NSInteger i = [partModelArray indexOfObject:part];
                UIView *view = (UIView *)[self.view viewWithTag:30001 + i];
                [view removeFromSuperview];
            }
        }

        [self updateShootGuide];
        DLYLogInfo(@"点击了已拍摄片段");
        cursorTag = selectPartTag;
        self.recordBtn.hidden = YES;
        self.playView.hidden = NO;
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showPlayButtonPopup"]){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showPlayButtonPopup"];
            self.normalBubble = [DLYPopupMenu showRelyOnView:self.playButton titles:@[@"预览视频片段"] icons:nil menuWidth:120 withState:self.newState delegate:self];
            self.normalBubble.showMaskAlpha = 1;
            self.normalBubble.flipState = self.newState;
        }
    }else
    {
        if (!self.playView.isHidden && self.playView) {
            [self.partBubble dismiss];
            if (self.partBubble) {
                [self.partBubble removeFromSuperview];
                self.partBubble = nil;
            }
            self.deletePartButton.selected = NO;
            [self.deletePartButton setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
            self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
            self.playView.hidden = YES;
        }
        self.recordBtn.hidden = NO;
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogVirtualPart *part1 = partModelArray[i];
            part1.prepareRecord = @"0";
        }
        part.prepareRecord = @"1";
        
        [self createPartViewLayout];
        
    }
}
#pragma mark ==== 创建选择场景view
- (void)createSceneView {
    [self.view addSubview:[self sceneView]];
    self.sceneDisapper = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 14, 14)];
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [self.sceneDisapper setHitEdgeInsets:edgeInsets];
    [self.sceneDisapper setImage:[UIImage imageWithIconName:IFShut inFont:ICONFONT size:14 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.sceneDisapper addTarget:self action:@selector(onClickCancelSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self.sceneView addSubview:self.sceneDisapper];
    
    self.chooseTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 130, 28)];
    self.chooseTitleLabel.centerX = self.sceneView.centerX;
    self.chooseTitleLabel.textColor = RGB(255, 255, 255);
    self.chooseTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.chooseTitleLabel.font = FONT_SYSTEM(20);
    self.chooseTitleLabel.text = @"选择拍摄场景";
    [self.sceneView addSubview:self.chooseTitleLabel];
    
    self.seeRush = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 70, 21, 50, 17)];
    [self.seeRush setImage:[UIImage imageWithIconName:IFShowVideo inFont:ICONFONT size:12 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.seeRush setTitle:@"样片" forState:UIControlStateNormal];
    [self.seeRush setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.seeRush.titleLabel.font = FONT_SYSTEM(12);
    [self.seeRush setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, -4)];
    [self.seeRush setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 4)];
    UIEdgeInsets seeRushedgeInsets = {-10, -10, -10, -10};
    [self.seeRush setHitEdgeInsets:seeRushedgeInsets];
    [self.seeRush addTarget:self action:@selector(showVideoView) forControlEvents:UIControlEventTouchUpInside];
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
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 7, 61, 61)];
        btn.tag = 1002 + i;
        btn.centerX = view.width / 2;
        [btn setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changeTypeStatus:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:btn];
        
        UILabel *typeName = [[UILabel alloc]initWithFrame:CGRectMake(0, btn.bottom, 70, 22)];
        typeName.tag = 2002 + i;
        typeName.centerX = view.width / 2;
        typeName.text = templateModel.templateTitle;
        typeName.adjustsFontSizeToFitWidth = YES;
        typeName.textColor = RGB(255, 255, 255);
        typeName.font = FONT_SYSTEM(16);
        typeName.textAlignment = NSTextAlignmentCenter;
        [view addSubview:typeName];
        
        if(i == selectType) {
            [btn setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 122, 0, 1)] forState:UIControlStateNormal];
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
    
    self.giveUpBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.alertLabel.bottom + 20, 61, 61)];
    self.giveUpBtn.centerX = self.sceneView.centerX - 46;
    [self.giveUpBtn setImage:[UIImage imageWithIconName:IFShut inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.giveUpBtn addTarget:self action:@selector(onGiveUpClickChangeTypeStatus) forControlEvents:UIControlEventTouchUpInside];
    self.giveUpBtn.layer.cornerRadius = 30.5;
    self.giveUpBtn.clipsToBounds = YES;
    self.giveUpBtn.layer.borderWidth = 1,0;
    self.giveUpBtn.layer.borderColor = RGB(255, 255, 255).CGColor;
    self.giveUpBtn.hidden = YES;
    [self.sceneView addSubview:self.giveUpBtn];
    
    self.sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.alertLabel.bottom + 20, 61, 61)];
    self.sureBtn.centerX = self.sceneView.centerX + 46;
    [self.sureBtn setImage:[UIImage imageWithIconName:IFSure inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.sureBtn addTarget:self action:@selector(onSureClickChangeTypeStatus) forControlEvents:UIControlEventTouchUpInside];
    self.sureBtn.layer.cornerRadius = 30.5;
    self.sureBtn.clipsToBounds = YES;
    self.sureBtn.layer.borderWidth = 1,0;
    self.sureBtn.layer.borderColor = RGB(255, 255, 255).CGColor;
    self.sureBtn.hidden = YES;
    [self.sceneView addSubview:self.sureBtn];
}
- (void)createFilterView {
    [self.view addSubview:[self filterContentView]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hiddenFilterContentView)];
    [self.filterContentView addGestureRecognizer:tap];
    [self.view addSubview:self.filterView];
    UITableView *filterTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, self.filterView.height/4, self.filterView.width, self.filterView.height/2) style:UITableViewStylePlain];
    filterTableView.delegate = self;
    filterTableView.dataSource = self;
    filterTableView.rowHeight = 50;
    filterTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    filterTableView.tableFooterView = [[UIView alloc]init];
    filterTableView.backgroundColor = [UIColor clearColor];
    [filterTableView registerClass:[DLYChooseFilterTableViewCell class] forCellReuseIdentifier:@"CELL"];
    [self.filterView addSubview:filterTableView];

}

- (void)createVideoView {
    
    [self.view addSubview:[self videoView]];
    self.videoDisapper = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 14, 14)];
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [self.videoDisapper setHitEdgeInsets:edgeInsets];
    [self.videoDisapper setImage:[UIImage imageWithIconName:IFBack inFont:ICONFONT size:14 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.videoDisapper addTarget:self action:@selector(hideVideoView) forControlEvents:UIControlEventTouchUpInside];
    [self.videoView addSubview:self.videoDisapper];
    
    self.videoTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 19, 130, 28)];
    self.videoTitleLabel.centerX = self.videoView.centerX;
    self.videoTitleLabel.textColor = RGB(255, 255, 255);
    self.videoTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.videoTitleLabel.font = FONT_SYSTEM(20);
    self.videoTitleLabel.text = @"观看样片";
    [self.videoView addSubview:self.videoTitleLabel];
    
    self.filmView = [[UIView alloc]initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 80, 190)];
    self.filmView.centerY = self.videoView.centerY;
    [self.videoView addSubview:self.filmView];
    UIScrollView * videoScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.filmView.width, self.filmView.height)];
    videoScrollView.showsVerticalScrollIndicator = NO;
    videoScrollView.showsHorizontalScrollIndicator = NO;
    videoScrollView.bounces = NO;
    [self.filmView addSubview:videoScrollView];
    
    float width = (self.filmView.width - 50)/6;
    videoScrollView.contentSize = CGSizeMake(width * 6 + 10 * 5, videoScrollView.height);
    videoArray = [NSMutableArray array];
    for(int i = 0; i < typeModelArray.count; i ++)
    {
        [videoArray addObject:typeModelArray[i]];
    }
    for(int i = 0; i < videoArray.count; i ++)
    {
        int wNum = i % 6;
        int hNum = i / 6;
        DLYMiniVlogTemplate *templateModel = videoArray[i];
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake((width + 10) * wNum, 100 * hNum, width, 90)];
        view.tag = 500 + i;
        [videoScrollView addSubview:view];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 31, 30, 30)];
        UIEdgeInsets edgeInsets = {-15, -15, -15, -15};
        [btn setHitEdgeInsets:edgeInsets];
        btn.tag = 600 + i;
        btn.centerX = view.width / 2;
        [btn setImage:[UIImage imageWithIconName:IFShowVideo inFont:ICONFONT size:30 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changeVideoToPlay:) forControlEvents:UIControlEventTouchUpInside];
        btn.backgroundColor = RGB(149, 145, 141);
        btn.layer.cornerRadius = 15;
        btn.clipsToBounds = YES;
        //        btn.layer.borderWidth = 1,0;
        //        btn.layer.borderColor = RGB(255, 255, 255).CGColor;
        [view addSubview:btn];
        
        UILabel *typeName = [[UILabel alloc]initWithFrame:CGRectMake(0, btn.bottom + 7, 70, 22)];
        typeName.tag = 700 + i;
        typeName.centerX = view.width / 2;
        typeName.text = templateModel.templateTitle;
        typeName.textColor = RGB(255, 255, 255);
        typeName.font = FONT_SYSTEM(16);
        typeName.textAlignment = NSTextAlignmentCenter;
        [view addSubview:typeName];
    }
}

//确定切换模板
- (void)onSureClickChangeTypeStatus {
    
    [self.resource removeCurrentAllPartFromDocument];
    
    //数组初始化，view布局
    if (!self.deleteButton.isHidden && self.deleteButton) {
        [self.allBubble dismiss];
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
        [self.partBubble dismiss];
        if (self.partBubble) {
            [self.partBubble removeFromSuperview];
            self.partBubble = nil;
        }
        self.deletePartButton.selected = NO;
        [self.deletePartButton setImage:[UIImage imageWithIconName:IFDetelePart inFont:ICONFONT size:24 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
        self.deletePartButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        self.playView.hidden = YES;
    }
    if (self.recordBtn.isHidden && self.recordBtn) {
        self.recordBtn.hidden = NO;
    }
    if (self.chooseFilter.isHidden && self.chooseFilter) {
        self.chooseFilter.hidden = NO;
    }
    if (self.chooseFilterLabel.isHidden && self.chooseFilterLabel) {
        self.chooseFilterLabel.hidden = NO;
    }
    [self changeSceneWithSelectNum:selectNewPartTag];
    [self initData];
    [self createPartViewLayout];
    
    self.alertLabel.hidden = YES;
    self.sureBtn.hidden = YES;
    self.giveUpBtn.hidden = YES;
    self.typeView.hidden = NO;
    self.seeRush.hidden = NO;
    
    DLYMiniVlogTemplate *template = self.session.currentTemplate;
    [DLYUserTrack recordAndEventKey:@"ChooseUseScene" andDescribeStr:template.templateTitle];
}
//放弃切换模板
- (void)onGiveUpClickChangeTypeStatus {
    
    self.alertLabel.hidden = YES;
    self.sureBtn.hidden = YES;
    self.giveUpBtn.hidden = YES;
    self.typeView.hidden = NO;
    self.seeRush.hidden = NO;
}
//点击某个模板
- (void)changeTypeStatus:(UIButton *)sender {
    
    NSInteger num = sender.tag - 1002;
    
    if(num == selectType) {
        [self cancelChooseSceneView];
        return;
    }
    
    BOOL isEmpty = YES;
    for (DLYMiniVlogVirtualPart *part in partModelArray) {
        if ([part.recordStatus isEqualToString:@"1"]) {
            isEmpty = NO;
        }
    }
    
    if (isEmpty) {
        //数组初始化，view布局 弹出选择
        [self.resource removeCurrentAllPartFromDocument];
        [self changeSceneWithSelectNum:num];
        [self initData];
        [self createPartViewLayout];
    }else {
        
        selectNewPartTag = num;
        self.typeView.hidden = YES;
        self.seeRush.hidden = YES;
        self.alertLabel.hidden = NO;
        self.sureBtn.hidden = NO;
        self.giveUpBtn.hidden = NO;
    }
}

- (void)changeSceneWithSelectNum:(NSInteger)num {
    
    selectType = num;
    DLYMiniVlogTemplate *template = typeModelArray[num];
    self.chooseSceneLabel.text = template.templateTitle;
    [self.session saveCurrentTemplateWithId:template.templateId version:template.version];
    
    for(int i = 0; i < typeModelArray.count; i++) {
        UIButton *btn = (UIButton *)[self.view viewWithTag:1002 + i];
        UILabel * typeName = (UILabel *)[self.view viewWithTag:2002 + i];
        if(num == i)
        {
            [btn setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 122, 0, 1)] forState:UIControlStateNormal];
            //            btn.layer.borderColor = RGB(255, 122, 0).CGColor;
            typeName.textColor = RGB(255, 122, 0);
            [self.chooseScene setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
            
        }else
        {
            [btn setImage:[UIImage imageWithIconName:[self.btnImg[i] integerValue] inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
            //            btn.layer.borderColor = RGB(255, 255, 255).CGColor;
            typeName.textColor = RGB(255, 255, 255);
        }
    }
    [UIView animateWithDuration:0.5f animations:^{
        self.sceneView.alpha = 0;
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(6, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(11, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(6, self.chooseFilter.bottom + 2, 50, 13);

        }else {
            self.toggleCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(SCREEN_WIDTH - 51, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(SCREEN_WIDTH - 51, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseFilter.bottom + 2, 50, 13);
        }
        self.toggleCameraBtn.hidden = NO;
        self.chooseScene.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.chooseFilter.hidden = NO;
        self.chooseFilterLabel.hidden = NO;
        self.backView.hidden = NO;
    
        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
            }else {
                self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
            }
            self.flashButton.hidden = NO;
        }
       
    } completion:^(BOOL finished) {
        self.sceneView.hidden = YES;
        [DLYUserTrack recordAndEventKey:@"ChooseSceneViewEnd"];
        [DLYUserTrack endRecordPageViewWith:@"ChooseSceneView"];
    }];
}

#pragma mark ==== 创建拍摄界面
- (void)createShootView {
    
    self.warningIcon = [[UIImageView alloc]initWithFrame:CGRectMake(28, SCREEN_HEIGHT - 54, 32, 32)];
    self.warningIcon.hidden = YES;
    self.warningIcon.image = [UIImage imageWithIconName:IFMute inFont:ICONFONT size:32 color:[UIColor redColor]];
    [self.shootView addSubview:self.warningIcon];
    
    self.shootGuide.centerX = _shootView.centerX;
    
    _timeView = [[UIView alloc] init];
    if (self.newState == 1) {
        self.timeView.frame = CGRectMake(SCREEN_WIDTH - 70, 0, 60, 60);
    }else {
        self.timeView.frame = CGRectMake(10, 0, 60, 60);
    }
    _timeView.centerY = self.shootView.centerY;
    [self.shootView addSubview:_timeView];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, _timeView.bottom + 40, 44, 44)];
    self.cancelButton.centerX = _timeView.centerX;
    self.cancelButton.backgroundColor = RGBA(0, 0, 0, 0.3);
    self.cancelButton.layer.cornerRadius = 22;
    self.cancelButton.clipsToBounds = YES;
    [self.cancelButton addTarget:self action:@selector(onClickCancelClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = FONT_SYSTEM(14);
    UIEdgeInsets edgeInsets = {-20, -20, -20, -20};
    [self.cancelButton setHitEdgeInsets:edgeInsets];
    [_shootView addSubview:self.cancelButton];
    
    _progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, _timeView.width, _timeView.height)];
    _progressView.circleRadius = 28;
    [_timeView addSubview:_progressView];
    
    //完成图片
    self.completeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.timeView.width, self.timeView.height)];
    self.completeButton.layer.borderWidth = 3.0;
    self.completeButton.layer.borderColor = RGB(255, 0, 0).CGColor;
    self.completeButton.layer.cornerRadius = self.timeView.width / 2.0;
    self.completeButton.clipsToBounds = YES;
    [self.completeButton setImage:[UIImage imageWithIconName:IFSuccessful inFont:ICONFONT size:30 color:RGB(255, 0, 0)] forState:UIControlStateNormal];
    self.completeButton.hidden = YES;
    [_timeView addSubview:self.completeButton];
    
    self.timeNumber = [[UILabel alloc]initWithFrame:CGRectMake(3, 3, 54, 54)];
    self.timeNumber.textColor = RGB(255, 255, 255);
    NSInteger partNumber = selectPartTag - 10000;
    DLYMiniVlogVirtualPart *part = partModelArray[partNumber - 1];
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
    }else {
        self.titleView.frame = CGRectMake(10, 20, 180, 30);
    }
    [self.shootView addSubview:self.titleView];
}

- (void)showControlView {
    
    [self createPartViewLayout];
    

    if (self.newState == 1) {
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 51;
        self.backView.frame = CGRectMake(SCREEN_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
    }else {
        self.backView.frame = CGRectMake(-180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);
        self.shootGuide.centerX = (SCREEN_WIDTH - 180 * SCALE_WIDTH - 51) / 2 + 180 * SCALE_WIDTH;
    }
    [UIView animateWithDuration:0.5f animations:^{
        if (self.newState == 1) {
            self.toggleCameraBtn.frame = CGRectMake(11, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(11, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(6, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(11, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(6, self.chooseFilter.bottom + 2, 50, 13);
            self.backView.frame = CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);

        }else {
            self.toggleCameraBtn.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 51, 40, 40);
            self.chooseScene.frame = CGRectMake(SCREEN_WIDTH - 51, 16, 40, 40);
            self.chooseSceneLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseScene.bottom + 2, 50, 13);
            self.chooseFilter.frame = CGRectMake(SCREEN_WIDTH - 51, 94, 40, 40);
            self.chooseFilterLabel.frame = CGRectMake(SCREEN_WIDTH - 56, self.chooseFilter.bottom + 2, 50, 13);
            self.backView.frame = CGRectMake(0, 0, 180 * SCALE_WIDTH, SCREEN_HEIGHT);

        }
        self.toggleCameraBtn.hidden = NO;
        self.chooseScene.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.chooseFilter.hidden = NO;
        self.chooseFilterLabel.hidden = NO;
        self.backView.hidden = NO;

        if (!isFront) {
            if (self.newState == 1) {
                self.flashButton.frame = CGRectMake(11, SCREEN_HEIGHT - 101, 40, 40);
            }else {
                self.flashButton.frame = CGRectMake(SCREEN_WIDTH - 51, SCREEN_HEIGHT - 101, 40, 40);
            }
            self.flashButton.hidden = NO;
        }

        self.shootView.alpha = 0;
        self.shootView.hidden = YES;
    } completion:^(BOOL finished) {
    }];
}

#pragma mark - 提示控件代理
- (void)indicatorViewStopFlashAnimating {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]]) {
        [DLYUserTrack recordAndEventKey:@"PartFinishTime"];
        [self showControlView];
        
        if (self.newState == 1) {
            self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeLeft;
            self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }else {
            self.AVEngine.captureVideoPreviewLayer.orientation = UIDeviceOrientationLandscapeRight;
            self.AVEngine.videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
        
        for(int i = 0; i < partModelArray.count; i++)
        {
            DLYMiniVlogVirtualPart *part = partModelArray[i];
            if ([part.recordStatus isEqualToString:@"0"]) {
                return;
            }
        }
        DLYLogInfo(@"完成后跳转");
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
                self.nextButton.center = self.view.center;
                self.deleteButton.frame = CGRectMake(self.view.centerX - 121, self.view.centerY - 30, 60, 60);
            }else {
                self.deleteButton.center = self.view.center;
                self.nextButton.frame = CGRectMake(self.view.centerX + 61, self.view.centerY - 30, 60, 60);
            }
            self.nextButton.hidden = NO;
            self.deleteButton.hidden = NO;
            if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showNextButtonPopup"]){
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNextButtonPopup"];
                self.nextStepBubble = [DLYPopupMenu showNextStepOnView:self.nextButton titles:@[@"去合成视频"] icons:nil menuWidth:120 withState:self.newState delegate:self];
                self.nextStepBubble.showMaskAlpha = 1;
                self.nextStepBubble.nextStepState = self.newState;
            }
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
    
    __weak typeof(self) weakSelf = self;
    self.alert.sureButtonAction = ^{
        [weakSelf gotoSetting];
    };
}
//跳转到设置
- (void)gotoSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}
#pragma mark ---tableview delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"CELL";
    DLYChooseFilterTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:cellID];
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        tableViewCell.title = @"无滤镜";
        if (!_isFilterTableViewHasSelected) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }else{
        tableViewCell.title = [[[DLYPhotoFilters sharedInstance] filterDisplayNames] objectAtIndex:indexPath.row-1];
    }
    return  tableViewCell;
    
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[DLYPhotoFilters sharedInstance]filterNames].count +1;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!_isFilterTableViewHasSelected) {
        _isFilterTableViewHasSelected = YES;
    }
    if (indexPath.row ==0) {
        [[DLYPhotoFilters sharedInstance]setFilterEnabled:NO];
//        [self.chooseFilter setImage:[UIImage imageWithIconName:IFNoFilter inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        self.chooseFilterLabel.text = @"";

    }else{
        [[DLYPhotoFilters sharedInstance]setFilterEnabled:YES];
        [[DLYPhotoFilters sharedInstance]setCurrentFilterIndex:indexPath.row -1];
//        [self.chooseFilter setImage:[UIImage imageWithIconName:IFFilter inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        self.chooseFilterLabel.text = [NSString stringWithFormat:@"%ld",indexPath.row];
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
- (UIView *)filterView {
    if(_filterView == nil)
    {
        _filterView = [[UIView alloc]initWithFrame:CGRectMake(61, 10, 120, SCREEN_HEIGHT-20)];
        _filterView.backgroundColor = RGBA(0, 0, 0, 0.7);
        _filterView.alpha = 1;
        _filterView.hidden = YES;
    }
    return _filterView;
}
- (UIView *)filterContentView {
    if(_filterContentView == nil)
    {
        _filterContentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _filterContentView.backgroundColor = [UIColor clearColor];
        _filterContentView.alpha = 1;
        _filterContentView.hidden = YES;
    }
    return _filterContentView;
}
- (UIView *)videoView {
    if(_videoView == nil)
    {
        _videoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _videoView.backgroundColor = RGBA(0, 0, 0, 1);
        _videoView.alpha = 1;
        _videoView.hidden = YES;
    }
    return _videoView;
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
- (double)getTimeWithString:(NSString *)timeString
{
    NSArray *stringArr = [timeString componentsSeparatedByString:@":"];
    NSString *timeStr_M = stringArr[0];
    NSString *timeStr_S = stringArr[1];
    NSString *timeStr_MS = stringArr[2];
    
    double timeNum_M = [timeStr_M doubleValue] * 60 * 1000;
    double timeNum_S = [timeStr_S doubleValue] * 1000;
    double timeNum_MS = [timeStr_MS doubleValue] * 10;
    double timeNum = timeNum_M + timeNum_S + timeNum_MS;
    return timeNum;
}
- (NSString *)getCurrentTime_MS {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss:SSS"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}
@end

