//
//  ALGridView.m
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import "ALGridView.h"

CGFloat kDefaultRowSpacing = 20.0f;
CGFloat kDefaultColumnSpacing = 30.0f;
CGFloat kDefaultTopMargin = 30.0f;
CGFloat kDefaultBottomMargin = 30.0f;
CGFloat kDefaultLeftMargin = 30.0f;
#define kDefaultItemSize CGSizeMake(60, 60)
CGFloat kDefaultAnimationInterval = 0.2f;
NSUInteger kDefaultReuseItemsNumber = 15;

const NSTimeInterval kInterEditingHoldInterval = 1.0;

@interface ALGridView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    ALGridViewCell *_dragCell;
    CGFloat _rowSpacing;
    CGFloat _columnSpacing;
    UITapGestureRecognizer *_endEditingGesture;
    CGFloat _offsetThreshold;
}

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSMutableDictionary *reuseQueue;

@end

@implementation ALGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _rowSpacing = kDefaultRowSpacing;
        _columnSpacing = kDefaultColumnSpacing;
        _items = [NSMutableArray array];
        _reuseQueue = [NSMutableDictionary dictionary];
        _topMargin = kDefaultTopMargin;
        _bottomMargin = kDefaultBottomMargin;
        _leftMargin = kDefaultLeftMargin;
        _editing = NO;
         
        self.multipleTouchEnabled = NO;
        self.clipsToBounds = YES;
        
        _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.showsVerticalScrollIndicator = NO;
        _contentView.delaysContentTouches = YES;
        _contentView.delegate = self;
        _contentView.multipleTouchEnabled = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        if ([_contentView respondsToSelector:@selector(setKeyboardDismissMode:)]) {
            [_contentView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
        }
        [self addSubview:_contentView];
        
        _endEditingGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerEndEditing:)];
//        _endEditingGesture.numberOfTapsRequired = 1;
//        _endEditingGesture.numberOfTouchesRequired = 1;
        _endEditingGesture.delaysTouchesBegan = YES;
        _endEditingGesture.delegate = self;
        [self addGestureRecognizer:_endEditingGesture];
    }
    return self;
}

- (void)setDelegate:(id<ALGridViewDelegate>)delegate
{
    if (!_delegate || ![_delegate isEqual:delegate]) {
        _delegate = delegate;
        if ([_delegate respondsToSelector:@selector(rowSpacingForGridView:)]) {
            _rowSpacing = [_delegate rowSpacingForGridView:self];
        } else {
            _rowSpacing = kDefaultRowSpacing;
        }
        if ([_delegate respondsToSelector:@selector(columnSpacingForGridView:)]) {
            _columnSpacing = [_delegate columnSpacingForGridView:self];
        } else {
            _columnSpacing = kDefaultColumnSpacing;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _contentView.alwaysBounceVertical = YES;
    [self updateScrollViewContentSize];
}

- (void)updateScrollViewContentSize
{
    NSInteger columnCount = [self numberOfColumns];
    NSInteger itemsCount = MAX(_items.count, [self numberOfItems]);
    CGSize itemSize = [self itemSize];
    
    NSInteger rowCount = (itemsCount / columnCount) + ((itemsCount % columnCount == 0) ? 0 : 1);
    CGFloat height = _topMargin + (itemSize.height + _rowSpacing) * rowCount - _rowSpacing + _bottomMargin;
    _contentView.contentSize = CGSizeMake(_contentView.contentSize.width, MAX(height, self.bounds.size.height));
}

- (NSInteger)numberOfColumns
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfColumnsInGridView:)]) {
        NSInteger columns = [_dataSource numberOfColumnsInGridView:self];
        return ((columns >= 0) ? columns : 0);
    }
    return 0;
}

- (NSInteger)numberOfItems
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfItemsInGridView:)]) {
        NSInteger itemsNumber = [_dataSource numberOfItemsInGridView:self];
        return ((itemsNumber >=0) ? itemsNumber : 0);
    }
    return 0;
}

- (CGSize)itemSize
{
    if (_delegate && [_delegate respondsToSelector:@selector(itemSizeForGridView:)]) {
        return [_delegate itemSizeForGridView:self];
    }
    return kDefaultItemSize;
}

- (void)setTopMargin:(CGFloat)topMargin
{
    if (_topMargin != topMargin) {
        _topMargin = topMargin;
        [self layoutItemsIsNeedAnimation:NO];
    }
}

- (void)setBottomMargin:(CGFloat)bottomMargin
{
    if (_bottomMargin != bottomMargin) {
        _bottomMargin = bottomMargin;
        [self layoutItemsIsNeedAnimation:NO];
    }
}

- (void)setLeftMargin:(CGFloat)leftMargin
{
    if (_leftMargin != leftMargin) {
        _leftMargin = leftMargin;
        [self layoutItemsIsNeedAnimation:NO];
    }
}

- (void)layoutItemsIsNeedAnimation:(BOOL)animation
{
    if (animation) {
        [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
            [self setAllItemsFrame];
        } completion:^(BOOL finished) {
            //可以执行必要操作
        }];
    } else {
        [self setAllItemsFrame];
    }
    [self layoutIfNeeded];
    [self updateScrollViewContentSize];
}

- (void)setAllItemsFrame
{
    for (int i = 0; i < _items.count; i++) {
        ALGridViewCell *cell = [self itemAtIndex:i];
        if (!cell || [cell isEqual:[NSNull null]]) {
            continue;
        }
        if (!cell.isDragging) {
            cell.transform = CGAffineTransformIdentity;
            CGRect frame = [self frameForItemAtIndex:i];
            cell.frame = [cell isEqual:_dragCell] ? [_contentView convertRect:frame toView:self] : frame;
        }
    }
}

- (CGRect)frameForItemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        NSInteger columnCount = [self numberOfColumns];
        NSInteger row = (index / columnCount) + ((index % columnCount == 0) ? 0 : 1);
        NSInteger column = index % columnCount;
        CGSize itemSize = [self itemSize];
        CGFloat x = _leftMargin + column * (itemSize.width + _columnSpacing);
        CGFloat y = _topMargin + row * (itemSize.height + _rowSpacing);
        return CGRectMake(x, y, itemSize.width, itemSize.height);
    }
    return CGRectZero;
}

- (NSInteger)indexOfItem:(ALGridViewCell *)cell
{
    if (cell) {
        return [_items indexOfObject:cell];
    }
    return -1;
}

- (ALGridViewCell *)itemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        ALGridViewCell *cell = [_items objectAtIndex:index];
        if ([cell isKindOfClass:[ALGridViewCell class]]) {
            return cell;
        }
    }
    return nil;
}

- (void)reloadData
{
    
}

- (ALGridViewCell *)gridViewCellAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        id object = [_items objectAtIndex:index];
        if ([object isKindOfClass:[ALGridViewCell class]]) {
            return (ALGridViewCell *)object;
        }
    }
    return nil;
}

- (BOOL)scrollEnabled
{
    return _contentView.scrollEnabled;
}

- (void)triggerEndEditing:(UITapGestureRecognizer *)gesture
{
    if (_editing && (gesture.state == UIGestureRecognizerStateEnded)) {
        _editing = NO;
        _contentView.delaysContentTouches = YES;
        _contentView.scrollEnabled = YES;
        
        [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
            for (ALGridViewCell *cell in _items) {
                if ([cell isEqual:[NSNull null]]) {
                    continue;
                }
                cell.transform = CGAffineTransformIdentity;
                cell.deleteButton.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [self layoutItemsIsNeedAnimation:NO];
            _dragCell = nil;
            [self endEditAnimationDidStopWithContext:nil finish:finished];
            if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidEndEditing:)]) {
                [_delegate ALGridViewDidEndEditing:self];
            }
        }];
    }
}

- (void)endEditAnimationDidStopWithContext:(void *)context finish:(BOOL)finish
{
    for (ALGridViewCell *cell in _items) {
        if ([cell isEqual:[NSNull null]]) {
            continue;
        }
        cell.editing = NO;
    }
}

- (BOOL)isEditing
{
    return _editing;
}

- (ALGridViewCell *)dequeueReusableItemWithIdentifier:(NSString *)reuseIdentifier
{
    if (!reuseIdentifier) {
        return nil;
    }
    NSMutableSet *set = [_reuseQueue objectForKey:reuseIdentifier];
    ALGridViewCell *cell = nil;
    if (set) {
        cell = [set anyObject];
        if (cell) {
            [set removeObject:cell];
            cell.hidden = NO;
        }
    }
    return cell;
}

- (void)enqueueReusableItem:(ALGridViewCell *)cell
{
    if ([cell isKindOfClass:[ALGridViewCell class]]) {
        [self removeCellEvents:cell];
        if ([cell respondsToSelector:@selector(prepareForReuse)]) {
            [cell prepareForReuse];
        }
        if ([cell.reuseIdentifier length]) {
            if (![_reuseQueue objectForKey:cell.reuseIdentifier]) {
                [_reuseQueue setObject:[NSMutableSet set] forKey:cell.reuseIdentifier];
            }
            NSMutableSet *set = [_reuseQueue objectForKey:cell.reuseIdentifier];
            if ([set count] <= kDefaultReuseItemsNumber) {
                [set addObject:cell];
            }
        }
        [cell removeFromSuperview];
    }
}

- (void)removeCellEvents:(ALGridViewCell *)cell
{
    if ([cell isKindOfClass:[ALGridViewCell class]]) {
        [cell removeTarget:self action:@selector(cellDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        [cell removeTarget:self action:@selector(cellDidTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [cell removeTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchUpOutside];
        [cell removeTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchCancel];
        [cell removeTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchDragExit];
        [cell.deleteButton removeTarget:self action:@selector(cellDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)configCellEvents:(ALGridViewCell *)cell
{
    if ([cell isKindOfClass:[ALGridViewCell class]]) {
        cell.editing = _editing;
        [cell addTarget:self action:@selector(cellDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        [cell addTarget:self action:@selector(cellDidTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [cell addTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchUpOutside];
        [cell addTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchCancel];
        [cell addTarget:self action:@selector(cellDidTouchUpOutSide:) forControlEvents:UIControlEventTouchDragExit];
        [cell.deleteButton addTarget:self action:@selector(cellDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - cell Events
- (void)cellDidTaped:(ALGridViewCell *)cell
{}

- (void)cellDidTouchDown:(ALGridViewCell *)cell withEvent:(UIEvent *)event
{}

- (void)cellDidTouchUpOutSide:(ALGridViewCell *)cell
{}

- (void)cellDeleteButtonDidTaped:(UIButton *)button
{}


























@end
