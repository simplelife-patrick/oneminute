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
@property (nonatomic, strong) UILabel *skipLabel;

@property (nonatomic, strong) DLYAnnularProgress * progressView;
@property (nonatomic, strong) UILabel *remindLabel;
@property (nonatomic, strong) UIView *centerView;

@property (nonatomic, strong) NSTimer *shootTimer;//定时器

@property (nonatomic, strong) UIButton *successButton;


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
    
    //测试定时器button，要删掉
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    btn.backgroundColor = [UIColor purpleColor];
    [self.syntheticView addSubview:btn];
    [btn addTarget:self action:@selector(onClickTimer) forControlEvents:UIControlEventTouchUpInside];
    
    //提示label
    self.remindLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 217, 112, 44)];
    self.remindLabel.centerX = self.view.centerX;
    self.remindLabel.textAlignment = NSTextAlignmentCenter;
    self.remindLabel.text = @"正在合成...";
    self.remindLabel.font = FONT_SYSTEM(16);
    self.remindLabel.textColor = [UIColor whiteColor];
    self.remindLabel.numberOfLines = 0;
    [self.syntheticView addSubview:self.remindLabel];
}

- (void)onClickTimer {
    
    _shootTime = 0.0;
    _shootTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(shootAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_shootTimer forMode:NSRunLoopCommonModes];
    
}

- (void)shootAction {
    _shootTime += 0.01;
    
    [_progressView drawProgress:0.1 * _shootTime withColor:RGB(255, 0, 0)];
    if(_shootTime > 9.99)
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        self.syntheticView.hidden = YES;
        //显示所有控件
        self.titleField.hidden = NO;
        self.skipButton.hidden = NO;
        self.skipLabel.hidden = NO;
        
        //逻辑 逻辑 逻辑
        [self.navigationController popToRootViewControllerAnimated:YES];
        
    });
    
    
}

- (void)createMainView {
    
    //背景图片
    UIImageView * videoImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SWitdh, SHeight)];
    videoImage.image = [UIImage imageNamed:@"timg"];
    [self.view addSubview:videoImage];
    
    //标题输入框
    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200 * SCALE_WIDTH, 42 * SCALE_HEIGHT)];
    self.titleField.center = self.view.center;
    self.titleField.delegate = self;
    self.titleField.placeholder = @"请输入标题";
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
    
    //跳过label
    self.skipLabel = [[UILabel alloc] init];
    self.skipLabel.font = FONT_SYSTEM(14);
    self.skipLabel.textColor = [UIColor whiteColor];
    self.skipLabel.text = @"跳过";
    [self.skipLabel sizeToFit];
    self.skipLabel.frame = CGRectMake(599.5 * S_WIDTH, 249 * S_HEIGHT, self.skipLabel.width, self.skipLabel.height);
    [self.view addSubview:self.skipLabel];
    
}

//跳过按钮点击事件
- (void)onClickSkip {
    
    //隐藏所有控件
    self.titleField.hidden = YES;
    self.skipButton.hidden = YES;
    self.skipLabel.hidden = YES;
    //显示导出UI
    self.syntheticView.hidden = NO;
    
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
        
        self.titleField.frame = rect;
    }];
}
//监听 键盘将要隐藏
- (void)hidechangeContentViewPosition:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    //回归位置
    [UIView animateWithDuration:duration.doubleValue animations:^{
        //        self.titleField.frame = CGRectMake(0, Main_Screen_Height - 49, Main_Screen_Width, 49);
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
//屏幕方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
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
