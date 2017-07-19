//
//  DLYBaseViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYBaseViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "DLYPopupMenu.h"


@interface DLYBaseViewController ()<YBPopupMenuDelegate>
@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, strong) NSMutableArray *viewArr;
@end

@implementation DLYBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.newState = 1;
    self.oldState = 1;
    [self startMotionManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    self.viewArr = [NSMutableArray arrayWithArray:[self.view subviews]];
    [self listSubviewsOfView:self.view];
    
    [self showPopupMenu];
    
}

- (void)showPopupMenu {
    
    for (UIView *view in self.viewArr) {
        
        if (view.isPopover == YES && view.isHidden == NO) {
            view.isPopover = NO;
            [DLYPopupMenu showRelyOnView:view titles:@[@"气泡"] icons:nil menuWidth:120 delegate:self];
            return;
        }
    }
    
}

- (void)listSubviewsOfView:(UIView *)view {
    
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) {
        
        [self.viewArr addObject:view];
        return;
    }
    
    for (UIView *subview in subviews) {
        
        // List the subviews of subview
        [self listSubviewsOfView:subview];
    }
}

- (void)ybPopupMenuDidDismiss {
    [self showPopupMenu];
}

- (void)viewControllerWillEnterForeground {
    
    NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

- (void)startMotionManager{
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    _motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (_motionManager.deviceMotionAvailable) {
        DLYLog(@"Device Motion Available");
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                                [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
                                                
                                            }];
    } else {
        DLYLog(@"No device motion on device.");
        [self setMotionManager:nil];
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y) >= fabs(x))
    {
        if (y >= 0){
            //倒立
//            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationPortraitUpsideDown];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }
        else{
            //直立
//            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        }
    }
    else
    {
        if (x >= 0){
            //home在左
//            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            
            self.newState = 2;
            if (self.newState != self.oldState) {
                [self deviceChangeAndHomeOnTheLeft];
                self.oldState = self.newState;
            }
        }
        else{
            //home在右
//            NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
//            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            
            self.newState = 1;
            if (self.newState != self.oldState) {
                [self deviceChangeAndHomeOnTheRight];
                self.oldState = self.newState;
            }

        }
    }
}

- (void)deviceChangeAndHomeOnTheLeft {

}

- (void)deviceChangeAndHomeOnTheRight {

}


- (void)stopMotionManager {
    
    [_motionManager stopDeviceMotionUpdates];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
