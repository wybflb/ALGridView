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

NSString *kShakeAnimationKey = @"shakeAnimation";

const NSTimeInterval kInterEditingHoldInterval = 1.0;

@interface ALGridView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    ALGridViewItem *_dragItem;
    CGFloat _rowSpacing;
    CGFloat _columnSpacing;
    UITapGestureRecognizer *_endEditingGesture;
    CGFloat _offsetThreshold;
    CGFloat _lastOffsetY;
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
        _offsetThreshold = frame.size.height / 4.0;
        _lastOffsetY = 0.0f;
         
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
    _offsetThreshold = CGRectGetHeight(_contentView.bounds) / 4.0;
    [self updateScrollViewContentSize];
}

- (void)updateScrollViewContentSize
{
    NSInteger columnCount = [self numberOfColumns];
    NSInteger itemsCount = MAX(_items.count, [self numberOfItems]);
    CGSize itemSize = [self itemSize];
    
    NSInteger rowCount = (itemsCount / columnCount) + ((itemsCount % columnCount == 0) ? 0 : 1);
    CGFloat height = _topMargin + (itemSize.height + _rowSpacing) * rowCount - _rowSpacing + _bottomMargin;
    _contentView.contentSize = CGSizeMake(CGRectGetWidth(_contentView.bounds), MAX(height, self.bounds.size.height));
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
        ALGridViewItem *item = [self itemAtIndex:i];
        if ([item isKindOfClass:[NSNull class]]) {
            continue;
        }
        if (!item.isDragging) {
            item.transform = CGAffineTransformIdentity;
            CGRect frame = [self frameForItemAtIndex:i];
            item.frame = [item isEqual:_dragItem] ? [_contentView convertRect:frame toView:self] : frame;
        }
    }
}

- (CGRect)frameForItemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        NSInteger columnCount = [self numberOfColumns];
        NSInteger row = (index / columnCount);
        NSInteger column = index % columnCount;
        CGSize itemSize = [self itemSize];
        CGFloat x = _leftMargin + column * (itemSize.width + _columnSpacing);
        CGFloat y = _topMargin + row * (itemSize.height + _rowSpacing);
        return CGRectMake(x, y, itemSize.width, itemSize.height);
    }
    return CGRectZero;
}

- (NSInteger)indexOfItem:(ALGridViewItem *)item
{
    return (item ? ([_items indexOfObject:item]) : (-1));
}

- (ALGridViewItem *)itemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        ALGridViewItem *item = [_items objectAtIndex:index];
        if ([item isKindOfClass:[ALGridViewItem class]]) {
            return item;
        }
    }
    return nil;
}

- (void)resetVariatesState
{
#warning 变量置空
    _dragItem = nil;
}

- (void)reloadData
{
    [self resetVariatesState];
    
    [self resetAllVisibleItems];
    [self updateScrollViewContentSize];
}

- (void)resetAllVisibleItems
{
    for (id object in _items) {
        if ([object respondsToSelector:@selector(removeFromSuperview)]) {
            [object performSelector:@selector(removeFromSuperview)];
        }
    }
    [_items removeAllObjects];
    CGRect visibleRect = CGRectMake(_contentView.contentOffset.x, _contentView.contentOffset.y, CGRectGetWidth(_contentView.bounds), CGRectGetHeight(_contentView.bounds));
    CGRect loadDataRect = CGRectInset(visibleRect, 0, -1 * _offsetThreshold);
    NSInteger totalItemsNumber = [self numberOfItems];
    
    for (NSInteger i = 0; i < totalItemsNumber; i++) {
        [_items addObject:[NSNull null]];
    }
    for (NSInteger index = 0; index < totalItemsNumber; index++) {
        CGRect frame = [self frameForItemAtIndex:index];
        if (CGRectIntersectsRect(loadDataRect, frame)) {
            if (_dataSource && [_dataSource respondsToSelector:@selector(ALGridView:itemAtIndex:)]) {
                ALGridViewItem *item = [_dataSource ALGridView:self itemAtIndex:index];
                item.frame = frame;
                [self configItemEvents:item];
                [_items replaceObjectAtIndex:index withObject:item];
                [_contentView addSubview:item];
            } else {
                NSException *exception = [NSException exceptionWithName:@"ALGridView DataSource" reason:@"no implementation for ALGridView dataSource method ALGridView:itemAtIndex:" userInfo:nil];
                [exception raise];
            }
        }
    }
}

- (void)removeAndAddItemsIfNecessary
{
    NSInteger totalItemsNumber = [self numberOfItems];
    if (totalItemsNumber < 1) {
        return;
    }
    
    CGRect visibleRect = CGRectMake(_contentView.contentOffset.x, _contentView.contentOffset.y, CGRectGetWidth(_contentView.bounds), CGRectGetHeight(_contentView.bounds));
    CGRect loadDataRect = CGRectInset(visibleRect, 0, -1 * _offsetThreshold);
    for (NSInteger index = 0; index < _items.count; index++) {
        CGRect frame = [self frameForItemAtIndex:index];
        ALGridViewItem *item = [self itemAtIndex:index];
        if (!CGRectIntersectsRect(loadDataRect, frame)) {
            if (item && ![item isEqual:_dragItem]) {
                [self enqueueReusableItem:item];
                [_items replaceObjectAtIndex:index withObject:[NSNull null]];
            }
        } else {
            if (!item) {
                if (_dataSource && [_dataSource respondsToSelector:@selector(ALGridView:itemAtIndex:)]) {
                    ALGridViewItem *item = [_dataSource ALGridView:self itemAtIndex:index];
                    item.frame = frame;
                    [self configItemEvents:item];
                    [_items replaceObjectAtIndex:index withObject:item];
                    [_contentView addSubview:item];
                } else {
                    NSException *exception = [NSException exceptionWithName:@"ALGridView DataSource" reason:@"no implementation for ALGridView dataSource method ALGridView:itemAtIndex:" userInfo:nil];
                    [exception raise];
                }
            }
        }
    }
}

- (void)deleteItemAtIndex:(NSInteger)index
{
    [self deleteItemAtIndex:index animation:nil];
}

- (void)deleteItemAtIndex:(NSInteger)index animation:(CAAnimation *)animation
{
    if (index < 0 || index > _items.count) {
        return;
    }
#warning do delete action
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
            for (ALGridViewItem *item in _items) {
                if ([item isEqual:[NSNull null]]) {
                    continue;
                }
                item.transform = CGAffineTransformIdentity;
                item.deleteButton.alpha = 0;
            }
        } completion:^(BOOL finished) {
            [self layoutItemsIsNeedAnimation:NO];
            _dragItem = nil;
            [self endEditAnimationDidStopWithContext:nil finish:finished];
            if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidEndEditing:)]) {
                [_delegate ALGridViewDidEndEditing:self];
            }
        }];
    }
}

- (void)endEditAnimationDidStopWithContext:(void *)context finish:(BOOL)finish
{
    for (ALGridViewItem *item in _items) {
        if ([item isEqual:[NSNull null]]) {
            continue;
        }
        item.editing = NO;
    }
}

- (BOOL)isEditing
{
    return _editing;
}

- (void)beginEditing
{
    if (_editing) {
        return;
    }
    _editing = YES;
    _contentView.delaysContentTouches = NO;
    
    for (ALGridViewItem *item in _items) {
        if ([item isKindOfClass:[NSNull class]]) {
            continue;
        }
        item.editing = YES;
        [item.deleteButton addTarget:self action:@selector(itemDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat rotation = 0.03;
        CABasicAnimation* shake = [CABasicAnimation animationWithKeyPath:@"transform"];
        shake.duration = 0.13;
        shake.autoreverses = YES;
        shake.repeatCount  = MAXFLOAT;
        shake.removedOnCompletion = NO;
        shake.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, -rotation, 0.0, 0.0, 1.0)];
        shake.toValue   = [NSValue valueWithCATransform3D:CATransform3DRotate(self.layer.transform, rotation, 0.0 ,0.0, 1.0)];
        [item.layer addAnimation:shake forKey:kShakeAnimationKey];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidBeginEditing:)]) {
        [_delegate ALGridViewDidBeginEditing:self];
    }
}

- (void)endEditing
{
    if (!_editing) {
        return;
    }
    _editing = NO;
    _contentView.delaysContentTouches = YES;
    _contentView.scrollEnabled = YES;
    [UIView animateWithDuration:0.3 animations:^{
        for (ALGridViewItem *item in _items) {
            if ([item isKindOfClass:[NSNull class]]) {
                continue;
            }
            item.deleteButton.alpha = 0;
        
            [item.layer removeAnimationForKey:kShakeAnimationKey];
            item.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {
        [self endEditingAnimationDidStop];
    }];
    
    [self layoutItemsIsNeedAnimation:NO];
    if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidEndEditing:)]) {
        [_delegate ALGridViewDidEndEditing:self];
    }
    
    [self resetVariatesState];
}

- (void)endEditingAnimationDidStop
{
    for (ALGridViewItem *item in _items) {
        if ([item isKindOfClass:[NSNull class]]) {
            continue;
        }
        item.editing = NO;
    }
}

- (ALGridViewItem *)dequeueReusableItemWithIdentifier:(NSString *)reuseIdentifier
{
    if (!reuseIdentifier) {
        return nil;
    }
    NSMutableSet *set = [_reuseQueue objectForKey:reuseIdentifier];
    ALGridViewItem *item = nil;
    if (set) {
        item = [set anyObject];
        if (item) {
            [set removeObject:item];
            item.hidden = NO;
        }
    }
    return item;
}

- (void)enqueueReusableItem:(ALGridViewItem *)item
{
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        [self removeItemEvents:item];
        if ([item respondsToSelector:@selector(prepareForReuse)]) {
            [item prepareForReuse];
        }
        if ([item.reuseIdentifier length]) {
            if (![_reuseQueue objectForKey:item.reuseIdentifier]) {
                [_reuseQueue setObject:[NSMutableSet set] forKey:item.reuseIdentifier];
            }
            NSMutableSet *set = [_reuseQueue objectForKey:item.reuseIdentifier];
            if ([set count] <= kDefaultReuseItemsNumber) {
                [set addObject:item];
            }
        }
        [item removeFromSuperview];
    }
}

- (void)removeItemEvents:(ALGridViewItem *)item
{
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        [item removeTarget:self action:@selector(itemDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        [item removeTarget:self action:@selector(itemDidTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [item removeTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchUpOutside];
        [item removeTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchCancel];
        [item removeTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchDragExit];
        [item.deleteButton removeTarget:self action:@selector(itemDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)configItemEvents:(ALGridViewItem *)item
{
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        item.editing = _editing;
        [item addTarget:self action:@selector(itemDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        [item addTarget:self action:@selector(itemDidTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [item addTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchUpOutside];
        [item addTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchCancel];
        [item addTarget:self action:@selector(itemDidTouchUpOutSide:) forControlEvents:UIControlEventTouchDragExit];
        [item.deleteButton addTarget:self action:@selector(itemDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - item Events
- (void)itemDidTaped:(ALGridViewItem *)item
{
    if (_editing) {
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(ALGridView:didSelectItemAtIndex:)]) {
        NSInteger index = [self indexOfItem:item];
        if (index != -1) {
            [item setSelected:YES];
            [item performSelector:@selector(setSelected:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.3];
            
            [_delegate ALGridView:self didSelectItemAtIndex:index];
        }
    }
}

- (void)itemDidTouchDown:(ALGridViewItem *)item withEvent:(UIEvent *)event
{}

- (void)itemDidTouchUpOutSide:(ALGridViewItem *)item
{}

- (void)itemDeleteButtonDidTaped:(UIButton *)button
{
    ALGridViewItem *item = (ALGridViewItem *)button.superview;
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        if (_delegate && [_delegate respondsToSelector:@selector(ALGridView:didTapedDeleteButtonWithIndex:)]) {
            [_delegate ALGridView:self didTapedDeleteButtonWithIndex:item.index];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat contentOffsetY = _contentView.contentOffset.y;
    //用户可能在为0的时候，向上拖拽
    if (contentOffsetY > 0) {
        CGFloat diff = 0;
#if __LP64__
        diff = fabs(_lastOffsetY - contentOffsetY);
#else
        diff = fabsf(_lastOffsetY - contentOffsetY);
#endif
        if (diff > _offsetThreshold) {
            _lastOffsetY = contentOffsetY;
            [self removeAndAddItemsIfNecessary];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidScroll:)]) {
        [_delegate ALGridViewDidScroll:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{}
// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0)
{}
// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
{}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if (_delegate && [_delegate respondsToSelector:@selector(ALGridViewDidScrollToTop:)]) {
        [_delegate ALGridViewDidScrollToTop:self];
    }
}





















@end
