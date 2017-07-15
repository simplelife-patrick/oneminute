//
//  DLYRecordViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYRecordViewController.h"
#import "DLYAnnularProgress.h"
//#import "FLEXManager.h"

#import "DLYPlayVideoViewController.h"

#import "UIButton+LargerHitArea.h"

@interface DLYRecordViewController ()<FPopUpViewDelegate>
{
    //    //记录选中的拍摄模式 10003 延时 10004 普通 10005 慢动作
    //    NSInteger selectModel;
    
    //记录选中的拍摄片段
    NSInteger selectVedioPart;
    
    //记录选中的样片类型
    NSInteger selectType;
    
    //记录白色闪动条的透明度
    NSInteger prepareAlpha;
    //选择的片段
    NSInteger selectPartTag;
    
    double _shootTime;
    
    NSMutableArray * partModelArray; //模拟存放拍摄片段的模型数组
    
    NSMutableArray * typeModelArray; //模拟选择样式的模型数组
    
}

@property (nonatomic, strong)UIView * mainView;  //主界面
@property (nonatomic, strong)UIView * sceneView; //选择场景的view
@property (nonatomic, strong)UIView * shootView; //拍摄界面

//进度条
@property (nonatomic, strong) UIView * timeView;
//计时器
//准备的计时器
@property (nonatomic, strong) NSTimer *timer;
//拍摄读秒计时器
@property (nonatomic, strong) NSTimer *shootTimer;
@property (nonatomic, assign) NSInteger prepareTime;
//@property (nonatomic, assign)float shootTime;

//准备拍摄片段闪烁的计时器
@property (nonatomic, strong) NSTimer * prepareShootTimer;

//环形进度条
@property (nonatomic, strong) DLYAnnularProgress * progressView;

@property (nonatomic, strong) NSMutableArray * shootStatusArray;

@property (nonatomic, strong) UIImageView *imageView;
///////////////////////////////
@property (nonatomic, strong) UIButton *chooseScene;        //选择场景
@property (nonatomic, strong) UILabel *chooseSceneLabel;    //选择场景文字
@property (nonatomic, strong) UIButton *exchangeCamera;     //切换摄像头
@property (nonatomic, strong) UIView *backView;             //控制页面底层
@property (nonatomic, strong) UIButton *shootButton;        //拍摄按钮
@property (nonatomic, strong) UIButton *nextButton;         //下一步按钮
@property (nonatomic, strong) UIButton *deleteButton;       //删除全部按钮
@property (nonatomic, strong) UIView *vedioEpisode;         //片段展示底部
@property (nonatomic, strong) UIScrollView *backScrollView; //片段展示滚图
@property (nonatomic, strong) UIView *playView;             //单个片段编辑页面
@property (nonatomic, strong) UIButton *playButton;         //播放单个视频
@property (nonatomic, strong) UIButton *deletePartButton;   //删除单个视频
@property (nonatomic, strong) UIView *prepareView;          //拍摄准备页面
@property (nonatomic, strong) UIImageView *warningIcon;     //拍摄指导
@property (nonatomic, strong) UILabel *shootGuide;          //拍摄指导
@property (nonatomic, strong) UIButton *canelButton;        //取消拍摄



@end

@implementation DLYRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    //创建假模型数据
    partModelArray = [[NSMutableArray alloc]init];
    for(int i = 0; i < 6; i ++)
    {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
        [dict setObject:@"0" forKey:@"shootStatus"];
        if(i == 0) {
            selectVedioPart = i;
            [dict setObject:@"1" forKey:@"prepareShoot"];
            [dict setObject:@"0" forKey:@"shootType"];
            [dict setObject:@"10''" forKey:@"time"];
        }else if(i == 1) {
            [dict setObject:@"0" forKey:@"prepareShoot"];
            [dict setObject:@"1" forKey:@"shootType"];
            [dict setObject:@"10''" forKey:@"time"];
        }else {
            [dict setObject:@"0" forKey:@"prepareShoot"];
            [dict setObject:@"0" forKey:@"shootType"];
            [dict setObject:@"10''" forKey:@"time"];
        }
        
        
        [partModelArray addObject:dict];
        
    }
    
    typeModelArray = [[NSMutableArray alloc]init];
    NSArray * typeNameArray = [[NSArray alloc]initWithObjects:@"通用",@"美食",@"运动",@"风景",@"人文",nil];
    for(int i = 0; i < 5; i ++)
    {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
        [dict setObject:typeNameArray[i] forKey:@"typeName"];
        [dict setObject:@"这里是介绍，最多两行文字" forKey:@"typeIntroduce"];
        [typeModelArray addObject:dict];
    }
    
    
    _shootTime = 0;
    //    selectModel = 10004;
    selectType = 0;
    _prepareTime = 0;
    selectPartTag = 0;
    for(int i = 0; i < 7; i ++)
    {
        [[self shootStatusArray] addObject:@"0"];
    }
    self.view.backgroundColor = RGB(247, 247, 247);
    [self.view addSubview:[self mainView]];
    [self createMainViewLeft];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (self.isExport) {
        
        //创建假模型数据
        [partModelArray removeAllObjects];
        for(int i = 0; i < 6; i ++)
        {
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:@"0" forKey:@"shootStatus"];
            if(i == 0) {
                selectVedioPart = i;
                [dict setObject:@"1" forKey:@"prepareShoot"];
                [dict setObject:@"0" forKey:@"shootType"];
                [dict setObject:@"10''" forKey:@"time"];
            }else if(i == 1) {
                [dict setObject:@"0" forKey:@"prepareShoot"];
                [dict setObject:@"1" forKey:@"shootType"];
                [dict setObject:@"10''" forKey:@"time"];
            }else {
                [dict setObject:@"0" forKey:@"prepareShoot"];
                [dict setObject:@"0" forKey:@"shootType"];
                [dict setObject:@"10''" forKey:@"time"];
            }
            
            [partModelArray addObject:dict];
            
        }
        
        _shootTime = 0;
        //    selectModel = 10004;
        selectType = 0;
        _prepareTime = 0;
        selectPartTag = 0;
        for(int i = 0; i < 7; i ++)
        {
            [[self shootStatusArray] addObject:@"0"];
        }
        
    }
    
    self.isExport = NO;
    [self createPartViewLayout];

}

#pragma mark ==== 主界面
- (void)createMainViewLeft {
    //通用button 选择场景button
    self.chooseScene = [[UIButton alloc]initWithFrame:CGRectMake(11, 16, 40, 40)];
    self.chooseScene.backgroundColor = RGBA(0, 0, 0, 0.4);
    [self.chooseScene setImage:[UIImage imageWithIcon:@"\U0000e665" inFont:ICONFONT size:22 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.chooseScene addTarget:self action:@selector(onClickChooseScene:) forControlEvents:UIControlEventTouchUpInside];
    self.chooseScene.layer.cornerRadius = 20;
    self.chooseScene.clipsToBounds = YES;
    self.chooseScene.titleLabel.font = FONT_SYSTEM(14);
    [self.chooseScene setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    [_mainView addSubview:self.chooseScene];
    //显示场景的label
    self.chooseSceneLabel = [[UILabel alloc]initWithFrame:CGRectMake(11, self.chooseScene.bottom + 2, 40, 13)];
    self.chooseSceneLabel.text = @"通用";
    self.chooseSceneLabel.font = FONT_SYSTEM(12);
    self.chooseSceneLabel.textColor = RGBA(255, 255, 255, 1);
    self.chooseSceneLabel.textAlignment = NSTextAlignmentCenter;
    [_mainView addSubview:self.chooseSceneLabel];
    
    
    //切换前置摄像头
    self.exchangeCamera = [[UIButton alloc]initWithFrame:CGRectMake(11, SCREEN_HRIGHT - 51, 40, 40)];
    //    DDLogInfo(@"wwidth = %d  height = %d",SCREEN_WIDTH,SCREEN_HRIGHT);
    self.exchangeCamera.layer.cornerRadius = 20;
    self.exchangeCamera.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.exchangeCamera.clipsToBounds = YES;
    [self.exchangeCamera setImage:[UIImage imageWithIcon:@"\U0000e668" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [self.exchangeCamera addTarget:self action:@selector(onClickexchangeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [_mainView addSubview:self.exchangeCamera];
    
    //右边的view
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 180 * SCALE_WIDTH, 0, 180 * SCALE_WIDTH, SCREEN_HRIGHT)];
    self.backView.backgroundColor = RGBA(0, 0, 0, 0.7);
    [_mainView addSubview:self.backView];
    
    //拍摄按钮
    self.shootButton = [[UIButton alloc]initWithFrame:CGRectMake(43 * SCALE_WIDTH, 0, 60*SCALE_WIDTH, 60 * SCALE_WIDTH)];
    self.shootButton.centerY = self.backView.centerY;
    [self.shootButton setImage:[UIImage imageWithIcon:@"\U0000e664" inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.shootButton.backgroundColor = RGB(255, 0, 0);
    self.shootButton.layer.cornerRadius = 30 * SCALE_WIDTH;
    self.shootButton.clipsToBounds = YES;
    [self.shootButton addTarget:self action:@selector(onClickShootVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.backView addSubview:self.shootButton];
    
    //跳转成片播放界面
    self.nextButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.nextButton.backgroundColor = RGB(255, 0, 0);
    self.nextButton.center = _mainView.center;
    self.nextButton.layer.cornerRadius = 30;
    self.nextButton.clipsToBounds = YES;
    self.nextButton.hidden = YES;
    [self.nextButton setImage:[UIImage imageNamed:@"next"] forState:UIControlStateNormal];
    self.nextButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    [self.nextButton addTarget:self action:@selector(onClickNextStep:) forControlEvents:UIControlEventTouchUpInside];
    [_mainView addSubview:self.nextButton];
    //删除全部片段
    self.deleteButton = [[UIButton alloc]initWithFrame:CGRectMake(self.nextButton.left - 91, self.nextButton.top, 60, 60)];
    self.deleteButton.layer.cornerRadius = 30;
    self.deleteButton.clipsToBounds = YES;
    self.deleteButton.backgroundColor = RGBA(0, 0, 0, 0.4);
    self.deleteButton.hidden = YES;
    [self.deleteButton setImage:[UIImage imageWithIcon:@"\U0000e669" inFont:ICONFONT size:20 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(onClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    [_mainView addSubview:self.deleteButton];
    
    //片段view
    self.vedioEpisode = [[UIView alloc]initWithFrame:CGRectMake(self.shootButton.right, 15 * SCALE_HEIGHT, 53, SCREEN_HRIGHT - 30  * SCALE_HEIGHT)];
    [self.backView addSubview:self.vedioEpisode];
    self.backScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, 53, self.vedioEpisode.height)];
    self.backScrollView.showsVerticalScrollIndicator = NO;
    self.backScrollView.showsHorizontalScrollIndicator = NO;
    self.backScrollView.bounces = NO;
    [self.vedioEpisode addSubview:self.backScrollView];
    float episodeHeight = (self.vedioEpisode.height - 10)/6;
    self.backScrollView.contentSize = CGSizeMake(15, episodeHeight * partModelArray.count + (partModelArray.count - 1) * 2);
    _prepareShootTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(prepareShootAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_prepareShootTimer forMode:NSRunLoopCommonModes];
    [_prepareShootTimer setFireDate:[NSDate distantFuture]];
    
    //右侧编辑页面
    self.playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.shootButton.x + self.shootButton.width, SCREEN_HRIGHT)];
    self.playView.hidden = YES;
    [self.backView addSubview:self.playView];
    //右侧：播放某个片段的button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(self.playView.width - 60 * SCALE_WIDTH, (SCREEN_HRIGHT - 152)/2, 60* SCALE_WIDTH, 60* SCALE_WIDTH)];
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
    
    UITapGestureRecognizer *skipGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
    //设置手势点击数,双击：点2下
    skipGesture.numberOfTapsRequired = 2;
    // imageView添加手势识别
    [self.shootView addGestureRecognizer:skipGesture];
    //    [self createShootView];
    
}
#pragma mark ==== 左手模式重新布局
//设备方向改变后调用的方法
//后面改变的状态
- (void)deviceChangeAndHomeOnTheLeft {
    
    [self createLeftPartView];
    
    if (!self.playView.isHidden) {
        UIButton *button = (UIButton *)[self.view viewWithTag:selectPartTag];
        //点击哪个item，光标移动到当前item
        self.prepareView.frame = CGRectMake(button.x, button.y + button.height - 2, 10, 2);
        [self.backScrollView insertSubview:button belowSubview:self.prepareView];
    }
    
}

//home在右 初始状态
- (void)deviceChangeAndHomeOnTheRight {
    
    [self createPartView];
    if (!self.playView.isHidden) {
        UIButton *button = (UIButton *)[self.view viewWithTag:selectPartTag];
        //点击哪个item，光标移动到当前item
        self.prepareView.frame = CGRectMake(button.x, button.y, 10, 2);
        [self.backScrollView insertSubview:button belowSubview:self.prepareView];
    }

}

- (void)againLayoutWithLeft {
    //左边控制器
    
    

}
#pragma mark ==== button点击事件
//选择场景
- (void)onClickChooseScene:(UIButton *)sender {
    
    DDLogInfo(@"点击通用");
    
    // 测试FLEX框架
//#if DEBUG
//    [[FLEXManager sharedManager] showExplorer];
//#endif
    
    [UIView animateWithDuration:0.5f animations:^{
        self.chooseScene.hidden = YES;
        self.exchangeCamera .hidden = YES;
        self.chooseSceneLabel.hidden = YES;
        self.backView.hidden = YES;
        self.sceneView.hidden = NO;
        self.sceneView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    
}
//切换摄像头
- (void)onClickexchangeCamera:(UIButton *)sender {
    
}
//拍摄按键
- (void)onClickShootVideo:(UIButton *)sender {
    
    DDLogInfo(@"拍摄按钮");
    [self.shootView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self createShootView];
    _shootTime = 0;
    _prepareTime = 0;
    for (NSDictionary * dict in partModelArray) {
        if([dict[@"prepareShoot"] isEqualToString:@"1"])
        {
            if([dict[@"shootType"] isEqualToString:@"1"])
            {
                self.warningIcon.hidden = NO;
                self.shootGuide.text = @"延时拍摄不能录制现场声音";
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
        self.exchangeCamera.hidden = YES;
        self.backView.hidden = YES;
        self.shootView.hidden = NO;
        self.shootView.alpha = 1;
    } completion:^(BOOL finished) {
        [_timer setFireDate:[NSDate distantPast]];
        
    }];
}
//跳转至下一个界面按键
- (void)onClickNextStep:(UIButton *)sender {
    DLYPlayVideoViewController * fvc = [[DLYPlayVideoViewController alloc]init];
    fvc.isAll = YES;
    [self.navigationController pushViewController:fvc animated:YES];
}
//删除视频
- (void)onClickDelete:(UIButton *)sender {
    
    [DLYAlertView showWithMessage:@"确定删除此片段？" AndCanelButton:@"取消" andSureButton:@"确定" delegate:self];
}
//播放某个片段
- (void)onClickPlayPartVideo:(UIButton *)sender{
    
    DLYPlayVideoViewController *playVC = [[DLYPlayVideoViewController alloc] init];
    playVC.isAll = NO;
    [self.navigationController pushViewController:playVC animated:YES];
    
}
//删除某个片段
- (void)onClickDeletePartVideo:(UIButton *)sender {
    
    [DLYAlertView showWithMessage:@"确定删除此片段？" AndCanelButton:@"取消" andSureButton:@"确定" delegate:self];
    DLYAlertView *fview = [[DLYAlertView alloc] init];
    fview.delegate = self;
    
}
//取消选择场景
- (void)onClickCancelSelect:(UIButton *)sender {
    
    [UIView animateWithDuration:0.5f animations:^{
        self.chooseScene.hidden = NO;
        self.exchangeCamera.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        self.sceneView.alpha = 0;
    } completion:^(BOOL finished) {
        self.sceneView.hidden = YES;
        
    }];
    
}
//选择场景页面点击事件
- (void)sceneViewClick : (id)sender {
    
    UIButton * button = (UIButton *)sender;
    NSInteger selectNum = button.tag/100;
    if(selectNum == 4)
    {//点击的事观看样片
        
    }else if(selectNum == 3)
    {//点击的事某个片段
        NSDictionary * dict = typeModelArray[button.tag - 300];
        self.chooseSceneLabel.text = dict[@"typeName"];
        [self changeTypeStatusWithTag:button.tag -300];
        
    }
}
//取消按键
- (void)onClickCancelClick:(UIButton *)sender {
    [_shootTimer invalidate];
    [UIView animateWithDuration:0.5f animations:^{
        self.chooseScene.hidden = NO;
        self.exchangeCamera .hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        self.shootView.alpha = 0;
    } completion:^(BOOL finished) {
        self.shootView.hidden = YES;
        
    }];
    
}

//手势 双击取消等待
- (void)handleTapGesture:(UITapGestureRecognizer *)skipGestureRecognizer {
    UILabel * label = (UILabel *)[self.view viewWithTag:94];
    UIView * point1 = (UIView *)[self.view viewWithTag:91];
    UIView * point2 = (UIView *)[self.view viewWithTag:92];
    UIView * point3 = (UIView *)[self.view viewWithTag:93];
        
    if (_timer.isValid) {
        point1.hidden = YES;
        point2.hidden = YES;
        point3.hidden = YES;
        [_timer invalidate];
        _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(shootAction) userInfo:nil repeats:YES];
        self.canelButton.hidden = NO;
        
        if(_prepareTime == 1 || label.hidden == NO){
            label.hidden = YES;
        }
    }
    

}
//代理方法,确定删除
- (void)deletePopUpViewClick {
    
    NSInteger i = selectPartTag - 10000;
    NSMutableDictionary * dict = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i-1]];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.playView.hidden = YES;
        self.shootButton.hidden = NO;
    } completion:^(BOOL finished) {
        
    }];
    
    for(int i = 0; i < partModelArray.count; i++)
    {
        NSMutableDictionary * dict1 = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i]];
        [dict1 setObject:@"0" forKey:@"prepareShoot"];
        [partModelArray replaceObjectAtIndex:i withObject:dict1];
    }
    dict[@"prepareShoot"] = @"0";
    dict[@"shootStatus"] = @"0";
    selectVedioPart = i - 1;
    [partModelArray replaceObjectAtIndex:i-1 withObject:dict];
    
    NSInteger n = 0;
    for(int i = 0; i < partModelArray.count; i++)
    {
        NSMutableDictionary * dict1 = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i]];
        if([dict1[@"shootStatus"] isEqualToString:@"0"])
        {
            selectVedioPart = i;
            dict1[@"prepareShoot"] = @"1";
            [partModelArray replaceObjectAtIndex:i withObject:dict1];
            
            break;
        }else
        {
            n++;
        }
    }
    
//    [self createPartView];
    [self createPartViewLayout];
}

- (void)createPartViewLayout {

    if (self.newState == 1) {
        [self createPartView];
    }else if (self.newState == 2){
        [self createLeftPartView];
    }

}

//代理方法,取消删除
- (void)cancelPopUpViewClick {
    
    
    
    
}

#pragma mark === 拍摄片段的view 暂定6个item
//需要重写一个相似的 只改变颜色,透明度等.显隐
- (void)createPartView {
    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HRIGHT - 30  * SCALE_HEIGHT - 10)/6;
    if(SCREEN_HRIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - 10)/6;
    }
    
    for(int i = 1; i <= partModelArray.count; i ++)
    {
        NSDictionary * dict = partModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(43, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        
        UIEdgeInsets edgeInsets = {0, -43, 0, -5};
        [button setHitEdgeInsets:edgeInsets];
        //辨别改变段是否已经拍摄
        if([dict[@"shootStatus"] isEqualToString:@"1"])
        {
            button.backgroundColor = RGB(255, 0, 0);
        }else
        {
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            // 辨别该片段是否是默认准备拍摄片段
            if([dict[@"prepareShoot"] isEqualToString:@"1"])
            {
                //光标
                self.prepareView = [[UIView alloc]initWithFrame:CGRectMake(button.x, button.y, 10, 2)];
                self.prepareView.backgroundColor = [UIColor whiteColor];
                [self.backScrollView addSubview:self.prepareView];
                prepareAlpha = 1;
                [_prepareShootTimer setFireDate:[NSDate distantPast]];
                //判断拍摄状态
                //正常状态
                if([dict[@"shootType"] isEqualToString:@"0"])
                {
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y, 39, button.height)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    [self.backScrollView addSubview:timeLabel];
                    
                }else if([dict[@"shootType"] isEqualToString:@"1"])
                {//快进
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y + button.height/2 - 13, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    [self.backScrollView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(button.left - 24,  button.y + button.height/2 +1, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"快进";
                    [self.backScrollView addSubview:speedLabel];
                    
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(speedLabel.left - 15, speedLabel.top, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [self.backScrollView addSubview:icon];
                }else
                {//延时
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y + button.height/2 - 13, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    [self.backScrollView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(button.left - 24,  button.y + button.height/2 +1, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"延时";
                    [self.backScrollView addSubview:speedLabel];
                    
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(speedLabel.left - 15, speedLabel.top, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    [self.backScrollView addSubview:icon];
                }
            }
        }
        
        
        button.tag = 10000 + i;
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
}

- (void)createLeftPartView {
    //    self.backView.transform = CGAffineTransformMakeRotation(M_PI);

    
    [self.backScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    float episodeHeight = (SCREEN_HRIGHT - 30  * SCALE_HEIGHT - 10)/6;
    if(SCREEN_HRIGHT > 420)
    {
        episodeHeight = (SCREEN_WIDTH - 30  * SCREEN_WIDTH/375 - 10)/6;
    }
    
    NSMutableArray *leftModelArray = [NSMutableArray arrayWithArray:partModelArray];
    leftModelArray = (NSMutableArray *)[[leftModelArray reverseObjectEnumerator] allObjects];
    
    for(int i = 1; i <= leftModelArray.count; i ++)
    {
        NSDictionary * dict = leftModelArray[i - 1];
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(43, (episodeHeight + 2) * (i - 1), 10, episodeHeight)];
        
        UIEdgeInsets edgeInsets = {0, -43, 0, -5};
        [button setHitEdgeInsets:edgeInsets];
        //辨别改变段是否已经拍摄
        if([dict[@"shootStatus"] isEqualToString:@"1"])
        {
            button.backgroundColor = RGB(255, 0, 0);
        }else
        {
            button.backgroundColor = RGBA_HEX(0xc9c9c9, 0.1);
            // 辨别该片段是否是默认准备拍摄片段
            if([dict[@"prepareShoot"] isEqualToString:@"1"])
            {
                //光标
                self.prepareView = [[UIView alloc]initWithFrame:CGRectMake(button.x, button.y + button.height - 2, 10, 2)];
                self.prepareView.backgroundColor = [UIColor whiteColor];
                [self.backScrollView addSubview:self.prepareView];
                prepareAlpha = 1;
                [_prepareShootTimer setFireDate:[NSDate distantPast]];
                //判断拍摄状态
                //正常状态
                if([dict[@"shootType"] isEqualToString:@"0"])
                {
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y, 39, button.height)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    timeLabel.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:timeLabel];
                    
                }else if([dict[@"shootType"] isEqualToString:@"1"])
                {//快进
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y + button.height/2 - 13, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    timeLabel.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(button.left - 24,  button.y + button.height/2 +1, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"快进";
                    speedLabel.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:speedLabel];
                    
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(speedLabel.left - 15, speedLabel.top, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e670" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    icon.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:icon];
                }else
                {//延时
                    UILabel * timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, button.y + button.height/2 - 13, 39, 12)];
                    timeLabel.textAlignment = NSTextAlignmentRight;
                    timeLabel.textColor = [UIColor whiteColor];
                    timeLabel.font = FONT_SYSTEM(11);
                    timeLabel.text = dict[@"time"];
                    timeLabel.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:timeLabel];
                    
                    UILabel * speedLabel = [[UILabel alloc]initWithFrame:CGRectMake(button.left - 24,  button.y + button.height/2 +1, 24, 12)];
                    speedLabel.textColor = [UIColor whiteColor];
                    speedLabel.font = FONT_SYSTEM(11);
                    speedLabel.text = @"延时";
                    speedLabel.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:speedLabel];
                    
                    
                    UIImageView * icon = [[UIImageView alloc]initWithFrame:CGRectMake(speedLabel.left - 15, speedLabel.top, 15, 14)];
                    icon.image = [UIImage imageWithIcon:@"\U0000e66f" inFont:ICONFONT size:19 color:[UIColor whiteColor]];
                    icon.transform = CGAffineTransformMakeRotation(M_PI);
                    [self.backScrollView addSubview:icon];
                }
            }
        }
        
        
//        button.tag = 10000 + i;
        button.tag = 10000 + (7 - i);
        [button addTarget:self action:@selector(vedioEpisodeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        button.clipsToBounds = YES;
        [self.backScrollView addSubview:button];
        
    }
}

- (void)prepareShootAction {
    
    [UIView animateWithDuration:0.1f animations:^{
        if(prepareAlpha == 1)
        {
            self.prepareView.alpha = 0;
        }else
        {
            self.prepareView.alpha = 1;
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

#pragma mark ===每个拍摄片段的点击事件
- (void)vedioEpisodeClick:(UIButton *)sender {
    UIButton * button = (UIButton *)sender;
    NSInteger i = button.tag - 10000;
    selectPartTag = button.tag;
    NSMutableDictionary * dict = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i-1]];
    //    NSDictionary * dict = partModelArray[i];
    
    //点击哪个item，光标移动到当前item
    
    if (self.newState == 1) {
        self.prepareView.frame = CGRectMake(button.x, button.y, 10, 2);
        [self.backScrollView insertSubview:button belowSubview:self.prepareView];
    }else if (self.newState == 2){
        self.prepareView.frame = CGRectMake(button.x, button.y + button.height - 2, 10, 2);
        [self.backScrollView insertSubview:button belowSubview:self.prepareView];
    }
    
    
    if([dict[@"shootStatus"] isEqualToString:@"1"])
    {//说明时已拍摄片段
        DDLogInfo(@"点击了已拍摄片段");
        [UIView animateWithDuration:0.5f animations:^{
            self.playView.hidden = NO;
            self.shootButton.hidden = YES;
        } completion:^(BOOL finished) {
            
        }];
    }else
    {
        self.playView.hidden = YES;
        self.shootButton.hidden = NO;
        for(int i = 0; i < partModelArray.count; i++)
        {
            NSMutableDictionary * dict1 = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i]];
            [dict1 setObject:@"0" forKey:@"prepareShoot"];
            [partModelArray replaceObjectAtIndex:i withObject:dict1];
        }
        dict[@"prepareShoot"] = @"1";
        selectVedioPart = i - 1;
        [partModelArray replaceObjectAtIndex:i-1 withObject:dict];
        
//        [self createPartView];
        [self createPartViewLayout];

    }
    
}
#pragma mark ==创建选择场景view
- (void)createSceneView {
    [self.view addSubview:[self sceneView]];
    UIButton * scenceDisapper = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 14, 14)];
    [scenceDisapper setImage:[UIImage imageWithIcon:@"\U0000e666" inFont:ICONFONT size:14 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
    [scenceDisapper addTarget:self action:@selector(onClickCancelSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self.sceneView addSubview:scenceDisapper];
    
    UIView * typeView = [[UIView alloc]initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 80, 162 * SCALE_HEIGHT)];
    typeView.centerY = self.sceneView.centerY;
    [self.sceneView addSubview:typeView];
    UIScrollView * typeScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, typeView.width, typeView.height)];
    typeScrollView.showsVerticalScrollIndicator = NO;
    typeScrollView.showsHorizontalScrollIndicator = NO;
    typeScrollView.bounces = NO;
    [typeView addSubview:typeScrollView];
    
    float width = (typeView.width - 40)/5;
    typeScrollView.contentSize = CGSizeMake(width * typeModelArray.count + 10 * (typeModelArray.count - 1), typeScrollView.height);
    for(int i = 0; i < typeModelArray.count; i ++)
    {
        NSDictionary * dcitModel = typeModelArray[i];
        UIView * view = [[UIView alloc]initWithFrame:CGRectMake((width + 10) * i, 0, width, typeView.height)];
        view.layer.cornerRadius = 5;
        view.clipsToBounds = YES;
        view.tag = 101 + i;
        [typeScrollView addSubview:view];
        
        UILabel * typeName = [[UILabel alloc]initWithFrame:CGRectMake(12, 19, 42, 21)];
        typeName.text = dcitModel[@"typeName"];
        typeName.textColor = RGB(255, 255, 255);
        typeName.font = FONT_BOLD(20);
        [view addSubview:typeName];
        
        UIImageView * selectImage = [[UIImageView alloc]initWithFrame:CGRectMake(view.width - 31, 20, 20, 16)];
        selectImage.image = [UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:20 color:RGBA(255, 255, 255, 1)];
        selectImage.tag = 10 + i;
        [view addSubview:selectImage];
        
        UILabel * detailLabel = [[UILabel alloc]initWithFrame:CGRectMake(11, typeName.bottom + 15, view.width - 26, 34)];
        detailLabel.text = dcitModel[@"typeIntroduce"];
        detailLabel.font = FONT_SYSTEM(14);
        detailLabel.textColor = RGBA(255, 255, 255, 0.6);
        detailLabel.numberOfLines = 2;
        [view addSubview:detailLabel];
        
        UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, view.width, view.height)];
        button.tag = 300 + i;
        [button addTarget:self action:@selector(sceneViewClick:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        UIButton * seeRush = [[UIButton alloc]initWithFrame:CGRectMake(0, view.height - 30, view.width - 10 * SCALE_WIDTH, 15)];
        [seeRush setImage:[UIImage imageWithIcon:@"\U0000e66c" inFont:ICONFONT size:12 color:RGBA(255, 255, 255, 1)] forState:UIControlStateNormal];
        [seeRush setTitle:@"观看样片" forState:UIControlStateNormal];
        [seeRush setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
        seeRush.titleLabel.font = FONT_SYSTEM(12);
        seeRush.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        seeRush.tag = 400 + i;
        [seeRush addTarget:self action:@selector(sceneViewClick:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:seeRush];
        
        
        if(i == selectType)
        {
            view.backgroundColor = RGB(24, 160, 230);
            selectImage.hidden = NO;
        }else
        {
            view.backgroundColor = RGBA(0, 0, 0, 0.5);
            selectImage.hidden = YES;
        }
        
    }
}

#pragma mark ===更改样片选中状态
- (void)changeTypeStatusWithTag : (NSInteger)num {
    if(num == selectType)
    {
        return;
    }
    selectType = num;
    for(int i = 0; i < typeModelArray.count; i++)
    {
        UIView * view = (UIView *)[self.view viewWithTag:101 + i];
        UIImageView * imageView = (UIImageView *)[self.view viewWithTag:10 + i];
        if(num == i)
        {
            view.backgroundColor = RGB(24, 160, 230);
            imageView.hidden = NO;
        }else
        {
            view.backgroundColor = RGBA(0, 0, 0, 0.5);
            imageView.hidden = YES;
        }
    }
    
    [UIView animateWithDuration:0.5f animations:^{
        self.sceneView.alpha = 0;
        self.chooseScene.hidden = NO;
        self.exchangeCamera.hidden = NO;
        self.chooseSceneLabel.hidden = NO;
        self.backView.hidden = NO;
        
    } completion:^(BOOL finished) {
        self.sceneView.hidden = YES;
        
    }];
}

#pragma mark ===创建拍摄界面
- (void)createShootView {
    
    self.warningIcon = [[UIImageView alloc]initWithFrame:CGRectMake(28, SCREEN_HRIGHT - 54, 32, 32)];
    self.warningIcon.hidden = YES;
    self.warningIcon.image = [UIImage imageWithIcon:@"\U0000e663" inFont:ICONFONT size:32 color:[UIColor redColor]];
    [self.shootView addSubview:self.warningIcon];
    
    UIView * secondPoint = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
    secondPoint.center = self.shootView.center;
    secondPoint.layer.cornerRadius = 10;
    secondPoint.backgroundColor = RGB(216, 216, 216);
    secondPoint.tag = 92;
    [self.shootView addSubview:secondPoint];
    
    UIView * firstPoint = [[UIView alloc]initWithFrame:CGRectMake(secondPoint.left - 30, 0, 20, 20)];
    firstPoint.centerY = self.shootView.centerY;
    firstPoint.layer.cornerRadius = 10;
    firstPoint.backgroundColor = RGB(216, 216, 216);
    firstPoint.tag = 91;
    [self.shootView addSubview:firstPoint];
    
    UIView * thirdPoint = [[UIView alloc]initWithFrame:CGRectMake(secondPoint.right + 10, 0, 20, 20)];
    thirdPoint.centerY = self.shootView.centerY;
    thirdPoint.layer.cornerRadius = 10;
    thirdPoint.backgroundColor = RGB(216, 216, 216);
    thirdPoint.tag = 93;
    [self.shootView addSubview:thirdPoint];
    
    UILabel * prepareLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, secondPoint.top - 35, 45, 25)];
    prepareLabel.centerX = self.shootView.centerX;
    prepareLabel.text = @"准备";
    prepareLabel.font = FONT_SYSTEM(20);
    prepareLabel.textColor = RGB(0, 0, 0);
    prepareLabel.tag = 94;
    [self.shootView addSubview:prepareLabel];
    
    self.shootGuide = [[UILabel alloc]initWithFrame:CGRectMake(0, SCREEN_HRIGHT - 49, 270, 30)];
    self.shootGuide.backgroundColor = RGBA(0, 0, 0, 0.7);
    self.shootGuide.text = @"拍摄指导：请保持光线充足";
    self.shootGuide.centerX = _shootView.centerX;
    self.shootGuide.textColor = RGB(255, 255, 255);
    self.shootGuide.font = FONT_SYSTEM(14);
    self.shootGuide.textAlignment = NSTextAlignmentCenter;
    [_shootView addSubview:self.shootGuide];
    
    _timeView = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 70, 0, 60, 60)];
    _timeView.centerY = self.shootView.centerY;
    [self.shootView addSubview:_timeView];
    
    self.canelButton = [[UIButton alloc]initWithFrame:CGRectMake(0, _timeView.bottom + 10, 30, 15)];
    self.canelButton.centerX = _timeView.centerX;
    [self.canelButton addTarget:self action:@selector(onClickCancelClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.canelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.canelButton setTitleColor:RGB(0, 0, 0) forState:UIControlStateNormal];
    self.canelButton.titleLabel.font = FONT_SYSTEM(14);
    self.canelButton.hidden = YES;
    [_shootView addSubview:self.canelButton];
    
    _progressView = [[DLYAnnularProgress alloc]initWithFrame:CGRectMake(0, 0, _timeView.width, _timeView.height)];
    _progressView.progress = 0.01;
    _progressView.circleRadius = 28;
    [_timeView addSubview:_progressView];
    
    UILabel * timeNumber = [[UILabel alloc]initWithFrame:CGRectMake(3, 3, 54, 54)];
    timeNumber.textColor = RGB(51, 51, 51);
    timeNumber.text = @"10";
    timeNumber.font = FONT_SYSTEM(20);
    timeNumber.textAlignment = NSTextAlignmentCenter;
    timeNumber.backgroundColor = RGBA(0, 0, 0, 0.3);
    timeNumber.layer.cornerRadius = 27
    ;
    timeNumber.clipsToBounds = YES;
    timeNumber.tag = 95;
    [_timeView addSubview:timeNumber];
    
    [self beginTime];
}

#pragma mark ====定时器
- (void)beginTime {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(action) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
}

- (void)action {
    UILabel * label = (UILabel *)[self.view viewWithTag:94];
    UIView * point1 = (UIView *)[self.view viewWithTag:91];
    UIView * point2 = (UIView *)[self.view viewWithTag:92];
    UIView * point3 = (UIView *)[self.view viewWithTag:93];
    _prepareTime ++;
    if(_prepareTime == 1)
    {
        label.hidden = YES;
    }else if(_prepareTime == 2)
    {
        point1.backgroundColor = RGB(152, 152, 152);
    }else if(_prepareTime == 3)
    {
        point2.backgroundColor = RGB(152, 152, 152);
    }else
    {
        point3.backgroundColor = RGB(152, 152, 152);
        point1.hidden = YES;
        point2.hidden = YES;
        point3.hidden = YES;
        [_timer invalidate];
        _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(shootAction) userInfo:nil repeats:YES];
        self.canelButton.hidden = NO;
        
    }
}
#pragma mark ==== 拍摄视频
- (void)shootAction {
    _shootTime += 0.01;
    
    if((int)(_shootTime * 100) % 100 == 0)
    {
        UILabel * label = (UILabel *)[self.view viewWithTag:95];
        label.text = [NSString stringWithFormat:@"%.0f",10 - _shootTime];
    }
    
    [_progressView drawProgress:0.1 * _shootTime];
    if(_shootTime > 9.99)
    {
        self.canelButton.hidden = YES;
        [[self shootStatusArray] replaceObjectAtIndex:selectVedioPart withObject:@"1"];
        [_shootTimer invalidate];
        
        NSMutableDictionary * dict = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[selectVedioPart]];
        for(int i = 0; i < partModelArray.count; i++)
        {
            NSMutableDictionary * dict1 = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i]];
            [dict1 setObject:@"0" forKey:@"prepareShoot"];
            [partModelArray replaceObjectAtIndex:i withObject:dict1];
        }
        dict[@"prepareShoot"] = @"0";
        dict[@"shootStatus"] = @"1";
        [partModelArray replaceObjectAtIndex:selectVedioPart withObject:dict];
        
        NSInteger n = 0;
        for(int i = 0; i < partModelArray.count; i++)
        {
            NSMutableDictionary * dict1 = [[NSMutableDictionary alloc]initWithDictionary:partModelArray[i]];
            if([dict1[@"shootStatus"] isEqualToString:@"0"])
            {
                selectVedioPart = i;
                dict1[@"prepareShoot"] = @"1";
                [partModelArray replaceObjectAtIndex:i withObject:dict1];
                
                break;
            }else
            {
                n++;
            }
        }
        
//        [self createPartView];
        [self createPartViewLayout];
        
        [UIView animateWithDuration:0.5f animations:^{
            self.exchangeCamera.hidden = NO;
            self.chooseScene.hidden = NO;
            self.chooseSceneLabel.hidden = NO;
            self.backView.hidden = NO;
            self.shootView.alpha = 0;
        } completion:^(BOOL finished) {
            self.shootView.hidden = YES;
            if(n == partModelArray.count)
            {//视频自动播放
                DLYPlayVideoViewController * fvc = [[DLYPlayVideoViewController alloc]init];
                fvc.isAll = YES;
                fvc.DismissBlock = ^{
                    self.shootButton.hidden = YES;
                    self.nextButton.hidden = NO;
                    self.deleteButton.hidden = NO;
                };
                [self.navigationController pushViewController:fvc animated:YES];
            }
        }];
    }
}

#pragma mark ==== 界面旋转，横屏
//是否允许旋转
//- (BOOL)shouldAutorotate
//{
//    return NO;
//}

//支持的旋转方向
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscape;
//}

//首选的旋转方向
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
//{
//    return UIInterfaceOrientationLandscapeLeft;
//}

//获得log路径?
- (NSArray*)getLogPath {
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString * logPath = [docPath stringByAppendingPathComponent:@"Caches"];
    logPath = [logPath stringByAppendingPathComponent:@"Logs"];
    
    
    NSFileManager * fileManger = [NSFileManager defaultManager];
    NSError * error = nil;
    NSArray * fileList = [[NSArray alloc]init];
    fileList = [fileManger contentsOfDirectoryAtPath:logPath error:&error];
    NSMutableArray * listArray = [[NSMutableArray alloc]init];
    for (NSString * oneLogPath in fileList)
    {
        if([oneLogPath characterAtIndex:0 ] == 'l')
        {
            NSString * truePath = [logPath stringByAppendingPathComponent:oneLogPath];
            [listArray addObject:truePath];
        }
    }
    return listArray;
    
}

#pragma mark === 懒加载
- (UIView *)mainView {
    if(_mainView == nil)
    {
        _mainView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HRIGHT)];
        _mainView.backgroundColor = RGB(70, 160, 235);
    }
    return _mainView;
}

- (UIView *)sceneView {
    if(_sceneView == nil)
    {
        _sceneView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HRIGHT)];
        _sceneView.backgroundColor = RGBA(0, 0, 0, 0.4);
        _sceneView.alpha = 0;
        _sceneView.hidden = YES;
    }
    return _sceneView;
}

- (UIView *)shootView {
    if(_shootView == nil)
    {
        _shootView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HRIGHT)];
        _shootView.backgroundColor = RGBA(247, 247, 247,0);
        _shootView.alpha = 0;
        _shootView.hidden = YES;
    }
    return _shootView;
}

- (NSMutableArray *)shootStatusArray {
    if(_shootStatusArray == nil)
    {
        _shootStatusArray = [[NSMutableArray alloc]init];
    }
    return _shootStatusArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
