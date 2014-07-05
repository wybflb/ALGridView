//
//  RootViewController.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "RootViewController.h"
#import "SecondViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(100, 100, 100, 70);
    [button setTitle:@"title" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonDidTaped:(UIButton *)button
{
    SecondViewController *_secondVC = [[SecondViewController alloc] init];
    [self.navigationController pushViewController:_secondVC animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self performSelector:@selector(resetData) withObject:nil afterDelay:3];
}

- (void)resetData
{
//    NSArray *array = [_gridView visibleItems];
//    for (NSInteger index = 0; index < array.count; index++) {
//        ALGridViewItem *item = [array objectAtIndex:index];
//        NSLog(@"%d,frame = %@", [_gridView indexOfItem:item], NSStringFromCGRect(item.frame));
//    }
//    NSMutableArray *array = [NSMutableArray array];
//    for (int i = 0; i < 20; i++) {
//        [array addObject:[NSNull null]];
//    }
//    [_viewData addObjectsFromArray:array];
//    _isReloadData = YES;
//    [_gridView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
