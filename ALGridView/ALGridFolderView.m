//
//  ALGridFolderView.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "ALGridFolderView.h"

@interface ALGridFolderView()

@property (nonatomic, retain) ALGridView *gridView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UITextField *titleField;
@property (nonatomic, retain) UIView *contentView;

@end

@implementation ALGridFolderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self commonInit];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
//    _titleField = [[UITextField alloc] initWithFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)]
}

- (void)setTitle:(NSString *)title
{
    if (![_title isEqualToString:title]) {
        _title = title;
        self.titleLabel.text = _title;
    }
}

@end
