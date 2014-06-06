//
//  RootViewController.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "RootViewController.h"
#import "ALGridView.h"

@interface RootViewController () <ALGridViewDataSource, ALGridViewDelegate>
{
    ALGridView *_gridView;
}

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
    _gridView = [[ALGridView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height)];
    _gridView.dataSource = self;
    _gridView.delegate = self;
    _gridView.topMargin = 30;
    _gridView.bottomMargin = 30;
    _gridView.leftMargin = 10;
    [self.view addSubview:_gridView];
    [_gridView reloadData];
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(50, 100, 70, 40);
//    [button setTitle:@"title" forState:UIControlStateNormal];
//    [button addTarget:self action:@selector(itemDidTaped:) forControlEvents:UIControlEventTouchUpInside];
//    [button addTarget:self action:@selector(itemDidTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
//    [button addTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchUpOutside];
//    [button addTarget:self action:@selector(itemDidTouchCancel:) forControlEvents:UIControlEventTouchCancel];
//    [button addTarget:self action:@selector(itemDidTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
//    [self.view addSubview:button];
}

- (void)itemDidTaped:(ALGridViewItem *)item
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)itemDidTouchDown:(ALGridViewItem *)item withEvent:(UIEvent *)event
{
     NSLog(@"%s", __FUNCTION__);
}

- (void)itemDidTouchUpOutSide:(ALGridViewItem *)item
{
    //手指超过control的边界
     NSLog(@"%s", __FUNCTION__);
}

- (void)itemDidTouchCancel:(UIButton *)button
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)itemDidTouchDragExit:(UIButton *)button
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ALGridViewDataSource
- (NSInteger)numberOfItemsInGridView:(ALGridView *)gridView
{
    return 100;
}

- (NSInteger)numberOfColumnsInGridView:(ALGridView *)gridView
{
    return 3;
}

- (ALGridViewItem *)ALGridView:(ALGridView *)gridView itemAtIndex:(NSInteger)index
{
    static NSString *reuserIdentifier = @"algridViewIdentifier";
    ALGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuserIdentifier];
    if (!item) {
        item = [[ALGridViewItem alloc] initWithReuseIdentifier:reuserIdentifier];
    }
    
    item.backgroundColor = [UIColor grayColor];
    return item;
}

#pragma mark - ALGridViewDelegate
- (CGSize)itemSizeForGridView:(ALGridView *)gridView
{
    return CGSizeMake(90, 90);
}

- (void)ALGridView:(ALGridView *)gridView didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"%s, %d", __FUNCTION__, index);
}

- (CGFloat)rowSpacingForGridView:(ALGridView *)gridView
{
    return 20;
}

- (CGFloat)columnSpacingForGridView:(ALGridView *)gridView
{
    return 10;
}

@end
