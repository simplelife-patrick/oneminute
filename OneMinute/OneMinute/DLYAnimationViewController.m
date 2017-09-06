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

@interface DLYAnimationViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *flashView;
@property (nonatomic, strong) NSTimer *flashTimer;
@property (nonatomic, assign) NSInteger num;

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
    
    self.flashView = [[UIView alloc] initWithFrame:CGRectMake(227 * SCALE_WIDTH, 164 * SCALE_HEIGHT, 30 * SCALE_WIDTH, 4 * SCALE_HEIGHT)];
    self.flashView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.flashView];
    
    self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(flashAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSRunLoopCommonModes];
    self.num = 0;
    
}

- (void)flashAnimation {
    
    self.num ++;
    if (self.num >= 18) {
        self.flashView.hidden = YES;
        [self.flashTimer invalidate];
        self.flashTimer = nil;
        [self enterNextViewController];
    }else {
        int i = self.num % 6;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
