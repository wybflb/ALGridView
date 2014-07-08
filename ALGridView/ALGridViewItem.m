//
//  ALGridViewCell.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "ALGridViewItem.h"
#import "ALGridView.h"

@implementation ALGridViewItem

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super init]) {
        self.reuseIdentifier = reuseIdentifier;
        self.dragging = NO;
        self.editing = NO;
        self.canDelete = YES;
//        self.canMove = YES;
        self.canTriggerEdit = YES;
        self.canLeaveCurrentView = YES;
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByCharWrapping;
        self.label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.label.frame = self.bounds;
}

//case the deleteButton is out of self's bounds,so overide this method to make sure the deleteButton can respond to touches that out of self's bounds but in deleteButton's bounds
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_deleteButton && CGRectContainsPoint(_deleteButton.frame, point)) {
        return YES;
    }
    
    return [super pointInside:point withEvent:event];
}

- (void)prepareForReuse
{
    self.editing = NO;
    self.dragging = NO;
    self.canDelete = YES;
    self.canTriggerEdit = YES;
    self.canLeaveCurrentView = YES;
}

#pragma mark - Touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (self.editing) {
        UIResponder *responder = nil;
        for (responder = self.nextResponder; responder; responder = responder.nextResponder) {
            if ([responder isKindOfClass:[ALGridView class]]) {
                break;
            }
        }
        if ([responder isKindOfClass:[ALGridView class]]) {
            [responder touchesBegan:touches withEvent:event];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (self.editing) {
        UIResponder *responder = nil;
        for (responder = self.nextResponder; responder; responder = responder.nextResponder) {
            if ([responder isKindOfClass:[ALGridView class]]) {
                break;
            }
        }
        if ([responder isKindOfClass:[ALGridView class]]) {
            [responder touchesMoved:touches withEvent:event];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (self.editing) {
        UIResponder *responder = nil;
        for (responder = self.nextResponder; responder; responder = responder.nextResponder) {
            if ([responder isKindOfClass:[ALGridView class]]) {
                break;
            }
        }
        if ([responder isKindOfClass:[ALGridView class]]) {
            [responder touchesEnded:touches withEvent:event];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (self.editing) {
        UIResponder *responder = nil;
        for (responder = self.nextResponder; responder; responder = responder.nextResponder) {
            if ([responder isKindOfClass:[ALGridView class]]) {
                break;
            }
        }
        if ([responder isKindOfClass:[ALGridView class]]) {
            [responder touchesCancelled:touches withEvent:event];
        }
    }
}

@end
