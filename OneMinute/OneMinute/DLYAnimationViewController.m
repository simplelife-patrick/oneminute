//
//  DLYAnimationViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/9/6.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYAnimationViewController.h"
#import "DLYLaunchPlayerViewController.h"
#import "DLYRecordViewController.h"
#import "DLYBaseNavigationController.h"
#import "AppDelegate.h"

@interface DLYAnimationViewController (){
    //上一个
    NSInteger oldTag;
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSTimer *flashTimer;
@property (nonatomic, assign) NSInteger num;
@property (nonatomic, strong) UIView *flashView;
@property (nonatomic, strong) UILabel *versionLabel;

@end

@implementation DLYAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createMainView];
}

- (void)createMainView {
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.imageView.image = [UIImage imageNamed:@"animation"];
    [self.view addSubview:self.imageView];
    
    for (int i = 0; i < 6; i++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(227 * SCALE_WIDTH + (35 * SCALE_WIDTH) * i, 164 * SCALE_HEIGHT, 30 * SCALE_WIDTH, 4 * SCALE_HEIGHT)];
        view.tag = 10000 + i;
        if (i == 2 || i == 3) {
            view.backgroundColor = RGB(70, 70, 70);
            view.alpha = 1;
        }else{
            view.backgroundColor = RGB(255, 255, 255);
            view.alpha = 0;
        }
        [self.view addSubview:view];
    }
    
    self.flashView = [[UIView alloc] initWithFrame:CGRectMake(227 * SCALE_WIDTH, 164 * SCALE_HEIGHT, 30 * SCALE_WIDTH, 4 * SCALE_HEIGHT)];
    self.flashView.backgroundColor = RGB(255, 255, 255);
    [self.view addSubview:self.flashView];
    
    self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(flashAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSRunLoopCommonModes];
    self.num = 0;
    
    self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 60, SCREEN_HEIGHT - 25, 60, 25)];
    self.versionLabel.textColor = RGB(134, 134, 134);
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [infoDic objectForKey:@"CFBundleVersion"];
    NSString *labelText = [NSString stringWithFormat:@"%@(%@)", appVersion,buildVersion];
    self.versionLabel.text = labelText;
    self.versionLabel.font = FONT_SYSTEM(14);
    [self.view addSubview:self.versionLabel];
}

- (void)flashAnimation {
    self.num ++;
    if (self.num >= 18) {
        self.flashView.alpha = 0;
        [self.flashTimer invalidate];
        self.flashTimer = nil;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self enterNextViewController];
        });
    }else {
        int i = self.num % 6;
        
        if (self.num == 3) {
            UIView *view = (UIView *)[self.view viewWithTag:10002];
            view.alpha = 0.7;
        }else if (self.num == 4){
            UIView *view = (UIView *)[self.view viewWithTag:10003];
            view.alpha = 0.7;
        }else if (self.num == 9){
            UIView *view = (UIView *)[self.view viewWithTag:10002];
            view.alpha = 0.3;
        }else if (self.num == 10){
            UIView *view = (UIView *)[self.view viewWithTag:10003];
            view.alpha = 0.3;
        }else if (self.num == 15){
            UIView *view = (UIView *)[self.view viewWithTag:10002];
            view.alpha = 0;
        }else if (self.num == 16){
            UIView *view = (UIView *)[self.view viewWithTag:10003];
            view.alpha = 0;
        }
        
        self.flashView.frame = CGRectMake(227 * SCALE_WIDTH + (35 * SCALE_WIDTH) * i, 164 * SCALE_HEIGHT, 30 * SCALE_WIDTH, 4 * SCALE_HEIGHT);
        
        if (self.newState == 1) {
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }else {
            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }
    }
}

- (void)enterNextViewController {
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"firstEnteraApp"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstEnteraApp"];
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        DLYLaunchPlayerViewController *vc = [[DLYLaunchPlayerViewController alloc] init];
        delegate.window.rootViewController = vc;
        [delegate.window makeKeyWindow];
        
    }else {
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        DLYRecordViewController *vc = [[DLYRecordViewController alloc] init];
        DLYBaseNavigationController *nvc = [[DLYBaseNavigationController alloc] initWithRootViewController:vc];
        delegate.window.rootViewController = nvc;
        [delegate.window makeKeyWindow];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [DLYUserTrack recordAndEventKey:@"PromoteVideoViewStart"];
    [DLYUserTrack beginRecordPageViewWith:@"PromoteVideoView"];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [DLYUserTrack recordAndEventKey:@"PromoteVideoViewEnd"];
    [DLYUserTrack endRecordPageViewWith:@"PromoteVideoView"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
