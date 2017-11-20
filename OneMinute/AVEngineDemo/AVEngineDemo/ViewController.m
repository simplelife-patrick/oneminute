//
//  ViewController.m
//  AVEngineDemo
//
//  Created by APPLE on 2017/11/13.
//  Copyright © 2017年 APPLE. All rights reserved.
//

#import "ViewController.h"
#import "NormalViewController.h"
#import "SlowMotionViewController.h"
#import "FastMotionViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSMutableArray *listArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTableView];

    // Do any additional setup after loading the view, typically from a nib.
}
-(NSMutableArray *)listArr{
    if (!_listArr) {
        _listArr = [NSMutableArray arrayWithObjects:@"创建一个常速视频，录制时长10秒",@"创建一个慢速视频，录制时长5秒",@"创建一个加速视频，录制时长20秒", nil];
    }
    return _listArr;
}

-(void)createTableView{
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, w, h) style:UITableViewStylePlain];
    _tableView.tableFooterView=[UIView new];
    _tableView.tableHeaderView = [UIView new];
    _tableView.rowHeight = 60;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listArr.count;
}
#pragma mark---加载cell数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID=@"cellID";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell==nil) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text=self.listArr[indexPath.row] ;
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    return cell;
}
#pragma mark---cell点击事件
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section!=0) {
        return;
    }
    if (indexPath.row == 0) {
        NormalViewController *vc = [[NormalViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 1) {
        SlowMotionViewController *vc = [[SlowMotionViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    if (indexPath.row == 2) {
        FastMotionViewController *vc = [[FastMotionViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
