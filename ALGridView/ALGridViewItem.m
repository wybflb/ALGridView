//
//  ALGridViewCell.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "ALGridViewItem.h"

@implementation ALGridViewItem

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super init]) {
        self.reuseIdentifier = reuseIdentifier;
        self.dragging = NO;
        self.editing = NO;
        self.canDelete = YES;
        self.canMove = YES;
        self.canTriggerEdit = YES;
        self.canLeaveCurrentView = YES;
    }
    return self;
}

@end
