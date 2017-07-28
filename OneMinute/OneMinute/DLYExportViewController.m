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

#define SWitdh [UIScreen mainScreen].bounds.size.width
#define SHeight [UIScreen mainScreen].bounds.size.height
#define S_WIDTH SWitdh/667
#define S_HEIGHT SHeight/375

@interface DLYExportViewController ()<UITextFieldDelegate>{
    
    double _shootTime;
}

@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UIView *syntheticView;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) UIButton *skipTestBtn;

@property (nonatomic, strong) DLYAnnularProgress * progressView;
@property (nonatomic, strong) UILabel *remindLabel;
@property (nonatomic, strong) UIView *centerView;

@property (nonatomic, strong) NSTimer *shootTimer;//定时器
@property (nonatomic, strong) UIButton *successButton;
@property (nonatomic, strong) UIView *backView;

@end

@implementation DLYExportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createMainView];
    [self createsyntheticView];
    
    //监听键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeContentViewPosition:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hidechangeContentViewPosition:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)createsyntheticView {
    
    [self.view addSubview:self.syntheticView];
    
    
    self.centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 133 * S_HEIGHT, 68, 68)];
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
    self.remindLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 217, 120, 44)];
    self.remindLabel.centerX = self.view.centerX;
    self.remindLabel.textAlignment = NSTextAlignmentCenter;
    self.remindLabel.text = @"正在合成...";
    self.remindLabel.font = FONT_SYSTEM(16);
    self.remindLabel.textColor = [UIColor whiteColor];
    self.remindLabel.numberOfLines = 0;
    [self.syntheticView addSubview:self.remindLabel];
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
//        self.syntheticView.hidden = YES;
//        //显示所有控件
//        self.titleField.hidden = NO;
//        self.skipButton.hidden = NO;
//        self.skipTestBtn.hidden = NO;
        NSArray *arr = self.navigationController.viewControllers;
        DLYRecordViewController *recoedVC = arr[0];
        recoedVC.isExport = YES;
        [self.navigationController popToViewController:recoedVC animated:YES];
    });
    
}

- (void)createMainView {
    
    //背景图片
    UIImageView * videoImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SWitdh, SHeight)];
    videoImage.image = [UIImage imageNamed:@"timg"];
    [self.view addSubview:videoImage];
    
    self.backView = [[UIView alloc] initWithFrame:self.view.frame];
    self.backView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backView];
    
    //标题输入框
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 300, 42)];
    self.titleField.center = self.view.center;
    self.titleField.delegate = self;
    self.titleField.placeholder = @"请输入标题";
    self.titleField.textAlignment = NSTextAlignmentCenter;
    [self.titleField setValue:RGB(255, 255, 255) forKeyPath:@"_placeholderLabel.textColor"];
    self.titleField.tintColor = RGB(255, 255, 255);
    self.titleField.font = FONT_SYSTEM(40);
    self.titleField.textColor = RGB(255, 255, 255);
    [self.view addSubview:self.titleField];
    
    //跳过button
    self.skipButton = [[UIButton alloc] initWithFrame:CGRectMake(582 * S_WIDTH, 158 * S_HEIGHT, 60 * S_WIDTH, 60 * S_WIDTH)];
    [self.skipButton setImage:[UIImage imageWithIcon:@"\U0000e66b" inFont:ICONFONT size:30 color:RGB(255, 255, 255)] forState:UIControlStateNormal];
    self.skipButton.backgroundColor = RGB(255, 0, 0);
    self.skipButton.layer.cornerRadius = 30 * S_WIDTH;
    self.skipButton.clipsToBounds = YES;
    [self.skipButton addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipButton];
    
    //跳过button
    self.skipTestBtn = [[UIButton alloc] init];
    [self.skipTestBtn setTitle:@"跳过" forState:UIControlStateNormal];
    [self.skipTestBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.skipTestBtn.titleLabel.font = FONT_SYSTEM(14);
    [self.skipTestBtn sizeToFit];
    self.skipTestBtn.frame = CGRectMake(599.5 * S_WIDTH, self.skipButton.bottom + 3, self.skipTestBtn.width, self.skipTestBtn.height);
    self.skipTestBtn.centerX = self.skipButton.centerX;
    [self.skipTestBtn addTarget:self action:@selector(onClickSkip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.skipTestBtn];
}

//跳过按钮点击事件
- (void)onClickSkip {
    
    [MobClick event:@"Skip"];
    //隐藏所有控件
    self.titleField.hidden = YES;
    self.skipButton.hidden = YES;
    self.skipTestBtn.hidden = YES;
    //显示导出UI
    self.syntheticView.hidden = NO;
    
    _shootTime = 0.0;
    _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(exportAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_shootTimer forMode:NSRunLoopCommonModes];

}

#pragma mark - 页面将要显示
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"ExportView"];
    if (self.newState == 1) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }else {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"ExportView"];
}
#pragma mark - 重写父类方法
- (void)deviceChangeAndHomeOnTheLeft {
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        NSLog(@"导出页面左转");
    }
}
- (void)deviceChangeAndHomeOnTheRight {
    
    NSArray *viewArr = self.navigationController.viewControllers;
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYExportViewController class]]) {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        NSLog(@"导出页面右转");
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
        self.backView.backgroundColor = [UIColor clearColor];
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
- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark ==== 懒加载
- (UIView *)syntheticView {
    if(_syntheticView == nil)
    {
        _syntheticView = [[UIView alloc]initWithFrame:self.view.frame];
        _syntheticView.backgroundColor = RGBA(0, 0, 0, 0.5);
        _syntheticView.hidden = YES;
    }
    return _syntheticView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
