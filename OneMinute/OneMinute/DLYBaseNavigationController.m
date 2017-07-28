//
//  DLYBaseNavigationController.m
//  OneMinute
//
//  Created by 陈立勇 on 2017/7/14.
//  Copyright © 2017年 动旅游. All rights reserved.
//

#import "DLYBaseNavigationController.h"
#import "DLYRecordViewController.h"

@interface DLYBaseNavigationController ()

@end

@implementation DLYBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    
    NSArray *viewArr = self.viewControllers;
    DLYRecordViewController *vc = viewArr[viewArr.count - 1];
    if ([viewArr[viewArr.count - 1] isKindOfClass:[DLYRecordViewController class]] && vc.isAppear == NO) {
            return NO;
    }else {
        return YES;
    }

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
