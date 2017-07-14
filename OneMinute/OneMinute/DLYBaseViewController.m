//
//  DLYBaseViewController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYBaseViewController.h"
#import <CoreMotion/CoreMotion.h>


@interface DLYBaseViewController ()
@property (nonatomic, strong) CMMotionManager * motionManager;


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

//即将进入前台
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
        NSLog(@"Device Motion Available");
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                                [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
                                                
                                            }];
    } else {
        NSLog(@"No device motion on device.");
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
