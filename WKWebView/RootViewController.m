//
//  RootViewController.m
//  WKWebView
//
//  Created by aDu on 2017/11/21.
//  Copyright © 2017年 DuKaiShun. All rights reserved.
//

#import "RootViewController.h"
#import "DKSWebController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"根视图";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 200, [UIScreen mainScreen].bounds.size.width - 200, 40);
    [btn addTarget:self action:@selector(loadHtml) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"加载HTML" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:btn];
}

- (void)loadHtml {
    DKSWebController *webVC = [[DKSWebController alloc] init];
    [webVC loadHtmlStr:@"http://www.baidu.com"];
    [self.navigationController pushViewController:webVC animated:YES];
}

@end
