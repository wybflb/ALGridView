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
NSString *kDeleteItemAnimationKey = @"deleteItemAnimationKey";
NSString *kAcceptItemUserInfoKey = @"acceptItemUserInfoKey";

const NSTimeInterval kEnterEditingHoldInterval = 1.0;
const NSTimeInterval kSpringHoldInterval = 1.0;
const NSTimeInterval kWillMergeItemHoldInterval = 0.8;
const NSTimeInterval kDidMergeItemHoldInterval = 1.2;
const NSTimeInterval kDragOutHoldInterval = 1.5;

#define ALTimerInvalidate(_timer) if (_timer) {[(_timer) invalidate]; (_timer) = nil;}
NSString *kTriggerEditingTimerItemKey = @"triggerEditingTimerItemKey";
NSString *kTriggerEditingTimerEventKey = @"triggerEditingTimerEventKey";

@interface ALGridView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    ALGridViewItem *_dragItem;
    ALGridViewItem *_accepterItem;
    CGFloat _rowSpacing;
    CGFloat _columnSpacing;
    UITapGestureRecognizer *_endEditingGesture;
    CGFloat _offsetThreshold;
    CGFloat _lastOffsetY;
    BOOL _springing;
    UITouch *_dragTouch;
    NSTimer *_triggerEditingHolderTimer;
    NSTimer *_springTimer;
    NSTimer *_willMergeHoldTimer;
    NSTimer *_didMergeHoldTimer;
    NSTimer *_dragOutHoldTimer;
    BOOL _isHoldTimer;
    NSInteger _willReceiverIndex;
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
        [self initVariates];
         
        self.multipleTouchEnabled = NO;
        self.clipsToBounds = YES;
        
        [self initContentView];
        
        _endEditingGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerEndEditing:)];
//        _endEditingGesture.numberOfTapsRequired = 1;
//        _endEditingGesture.numberOfTouchesRequired = 1;
        _endEditingGesture.delaysTouchesBegan = YES;
        _endEditingGesture.delegate = self;
        [self addGestureRecognizer:_endEditingGesture];
    }
    return self;
}

- (void)initVariates
{
    _items = [NSMutableArray array];
    _reuseQueue = [NSMutableDictionary dictionary];
    _rowSpacing = kDefaultRowSpacing;
    _columnSpacing = kDefaultColumnSpacing;
    _topMargin = kDefaultTopMargin;
    _bottomMargin = kDefaultBottomMargin;
    _leftMargin = kDefaultLeftMargin;
    _editing = NO;
    _canEdit = YES;
    _scrollMode = ALGridViewScrollModeVertical;
    _offsetThreshold = self.frame.size.height / 4.0;
    _lastOffsetY = 0.0f;
    _springing = NO;
    _dragTouch = nil;
    _dragItem = nil;
    _accepterItem = nil;
    _triggerEditingHolderTimer = nil;
    _canCreateFolder = NO;
    _willReceiverIndex = -2;
    _isHoldTimer = NO;
}

- (void)initContentView
{
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _contentView.showsHorizontalScrollIndicator = NO;
    _contentView.showsVerticalScrollIndicator = NO;
    _contentView.delaysContentTouches = YES;
    _contentView.delegate = self;
    _contentView.multipleTouchEnabled = NO;
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.bounces = YES;
    _contentView.pagingEnabled = NO;
    if ([_contentView respondsToSelector:@selector(setKeyboardDismissMode:)]) {
        [_contentView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
    }
    [self addSubview:_contentView];
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

- (void)setScrollMode:(ALGridViewScrollMode)scrollMode
{
    if (_scrollMode != scrollMode) {
        _scrollMode = scrollMode;
        _contentView.pagingEnabled = (_scrollMode == ALGridViewScrollModeHorizontal);
        if (_scrollMode == ALGridViewScrollModeHorizontal) {
            _offsetThreshold = CGRectGetWidth(_contentView.bounds);
            _contentView.bounces = NO;
        } else {
            _offsetThreshold = CGRectGetHeight(_contentView.bounds) / 4.0;
            _contentView.bounces = YES;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _contentView.alwaysBounceVertical = YES;
    [self updateScrollViewContentSize];
}

- (NSInteger)numberOfItemsPerPageForHorizontalScroll
{
    NSInteger columnCount = [self numberOfColumns];
    CGSize itemSize = [self itemSize];
    NSInteger rowCountPerPage = 1;
    CGFloat contentHeight  = CGRectGetHeight(_contentView.bounds);
    while (_topMargin + (itemSize.height + _rowSpacing) * rowCountPerPage - _rowSpacing + _bottomMargin <  contentHeight) {
        rowCountPerPage++;
    }
    rowCountPerPage -= 1;
    
    return rowCountPerPage * columnCount;
}

- (NSInteger)numberOfPagesForHorizontalScroll
{
    if (_scrollMode != ALGridViewScrollModeHorizontal) {
        return -1;
    }
    NSInteger itemCount = [self numberOfItems];
    return (itemCount / [self numberOfItemsPerPageForHorizontalScroll]) + (itemCount % [self numberOfItemsPerPageForHorizontalScroll] == 0 ? 0 : 1);
}

- (void)updateScrollViewContentSize
{
    NSInteger columnCount = [self numberOfColumns];
    if (columnCount < 1) {
        return;
    }
    NSInteger itemsCount = MAX(_items.count, [self numberOfItems]);
    CGSize itemSize = [self itemSize];
    if (_scrollMode == ALGridViewScrollModeVertical) {
        NSInteger rowCount = (itemsCount / columnCount) + ((itemsCount % columnCount == 0) ? 0 : 1);
        CGFloat height = _topMargin + (itemSize.height + _rowSpacing) * rowCount - _rowSpacing + _bottomMargin;
        _contentView.contentSize = CGSizeMake(CGRectGetWidth(_contentView.bounds), MAX(height, self.bounds.size.height));
    } else {
        NSInteger itemCountPerPage = [self numberOfItemsPerPageForHorizontalScroll];
        NSInteger pages = itemsCount / itemCountPerPage + (itemsCount % itemCountPerPage == 0 ? 0 : 1);
        CGFloat width = pages * _contentView.bounds.size.width * 1.0;
        _contentView.contentSize = CGSizeMake(MAX(self.bounds.size.width, width), CGRectGetHeight(_contentView.bounds));
    }
}

- (NSInteger)numberOfColumns
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfColumnsInGridView:)]) {
        NSInteger columns = [_dataSource numberOfColumnsInGridView:self];
        return ((columns >= 0) ? columns : 0);
    } else {
        NSException *exception = [NSException exceptionWithName:@"ALGridView exception" reason:@"the ALGridView's data source method - numberOfColumnsInGridView: isn't found" userInfo:nil];
        [exception raise];
    }
    return 0;
}

- (NSInteger)numberOfItems
{
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfItemsInGridView:)]) {
        NSInteger itemsNumber = [_dataSource numberOfItemsInGridView:self];
        return ((itemsNumber >= 0) ? itemsNumber : 0);
    } else {
        NSException *exception = [NSException exceptionWithName:@"ALGridView exception" reason:@"the ALGridView's data source method - numberOfItemsInGridView: isn't found" userInfo:nil];
        [exception raise];
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
        if (!item || [item isKindOfClass:[NSNull class]]) {
            continue;
        }
        if (!item.isDragging) {
            item.transform = CGAffineTransformIdentity;
            CGRect frame = [self frameForItemAtIndex:i];
            item.frame = frame;
//            item.frame = [item isEqual:_dragItem] ? [_contentView convertRect:frame toView:self] : frame;
        }
    }
}

- (CGRect)frameForItemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _items.count) {
        NSInteger columnCount = [self numberOfColumns];
        if (columnCount < 1) {
            return CGRectZero;
        }
        CGSize itemSize = [self itemSize];
        if (_scrollMode == ALGridViewScrollModeVertical) {
            NSInteger row = (index / columnCount);
            NSInteger column = index % columnCount;
            CGFloat x = _leftMargin + column * (itemSize.width + _columnSpacing);
            CGFloat y = _topMargin + row * (itemSize.height + _rowSpacing);
            return CGRectMake(x, y, itemSize.width, itemSize.height);
        } else {
            NSInteger itemCountPerPage = [self numberOfItemsPerPageForHorizontalScroll];
            NSInteger relativeIndex = index % itemCountPerPage; //由0开始
            NSInteger row = relativeIndex / columnCount; //由0开始
            NSInteger page = index / itemCountPerPage; //由0开始
            NSInteger relativeColumn = relativeIndex % columnCount;
            CGFloat x = page * CGRectGetWidth(self.bounds) + _leftMargin + relativeColumn * (itemSize.width + _columnSpacing);
            CGFloat y = _topMargin + row * (itemSize.height + _rowSpacing);
            return CGRectMake(x, y, itemSize.width, itemSize.height);
        }
    }
    return CGRectZero;
}

- (NSInteger)indexOfItem:(ALGridViewItem *)item
{
    return (item ? ([_items indexOfObject:item]) : (-1));
}

- (ALGridViewItem *)itemAtIndex:(NSUInteger)index
{
    if (index < _items.count) {
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
    _springing = NO;
    _dragTouch = nil;
    _accepterItem = nil;
    _isHoldTimer = NO;
    _willReceiverIndex = -2;
    
    ALTimerInvalidate(_triggerEditingHolderTimer)
    ALTimerInvalidate(_springTimer)
    ALTimerInvalidate(_willMergeHoldTimer)
    ALTimerInvalidate(_didMergeHoldTimer)
    ALTimerInvalidate(_dragOutHoldTimer)
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
        if ([object isKindOfClass:[ALGridViewItem class]]) {
            [self enqueueReusableItem:object];
            [object performSelector:@selector(removeFromSuperview)];
        }
    }
    [_items removeAllObjects];
    
    CGRect visibleRect = [self visibleRect];
    CGRect loadDataRect = CGRectInset(visibleRect, 0, -1 * _offsetThreshold);
    
    if (_scrollMode == ALGridViewScrollModeHorizontal) {
        loadDataRect = CGRectInset(visibleRect, - CGRectGetWidth(_contentView.bounds), 0);
    }
    
    NSInteger totalItemsNumber = [self numberOfItems];
    
    for (NSInteger i = 0; i < totalItemsNumber; i++) {
        [_items addObject:[NSNull null]];
    }
    BOOL _isFoundFirstLoadItem = NO;
    for (NSInteger index = 0; index < totalItemsNumber; index++) {
        CGRect frame = [self frameForItemAtIndex:index];
        if (CGRectIntersectsRect(loadDataRect, frame)) {
            if (!_isFoundFirstLoadItem) {
                _isFoundFirstLoadItem = YES;
            }
            if (_dataSource && [_dataSource respondsToSelector:@selector(gridView:itemAtIndex:)]) {
                ALGridViewItem *item = [_dataSource gridView:self itemAtIndex:index];
                item.frame = frame;
                [self configEventsForItem:item];
                [_items replaceObjectAtIndex:index withObject:item];
                [_contentView addSubview:item];
            } else {
                NSException *exception = [NSException exceptionWithName:@"ALGridView exception" reason:@"no implementation for ALGridView's dataSource method - ALGridView:itemAtIndex:" userInfo:nil];
                [exception raise];
            }
        } else {
            if (_isFoundFirstLoadItem) {
                break;
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
    
    CGRect visibleRect = [self visibleRect];
    CGRect loadDataRect = CGRectInset(visibleRect, 0, -1 * _offsetThreshold);
    if (_scrollMode == ALGridViewScrollModeHorizontal) {
        loadDataRect = CGRectInset(visibleRect, -_offsetThreshold, 0);
    }
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
                if (_dataSource && [_dataSource respondsToSelector:@selector(gridView:itemAtIndex:)]) {
                    ALGridViewItem *item = [_dataSource gridView:self itemAtIndex:index];
                    item.frame = frame;
                    item.editing = _editing;
                    [self configEventsForItem:item];
                    [_items replaceObjectAtIndex:index withObject:item];
                    [_contentView addSubview:item];
                    if (_editing) {
                        [self addShakeAnimationForItem:item];
                    } else {
                        [self removeShakeAnimationForItem:item];
                    }
                } else {
                    NSException *exception = [NSException exceptionWithName:@"ALGridView exception" reason:@"no implementation for ALGridView's dataSource method -ALGridView:itemAtIndex:" userInfo:nil];
                    [exception raise];
                }
            }
        }
    }
}

- (void)deleteItemAtIndex:(NSUInteger)index isNeedAnimation:(BOOL)needAnimation
{
    if (needAnimation) {
        ALGridViewItem *item = [_items objectAtIndex:index];
        if (![item isKindOfClass:[ALGridViewItem class]] || !item.canDelete) {
            return;
        }
        CGRect itemFrame = [self frameForItemAtIndex:index];
        CGRect newFrame = CGRectMake(CGRectGetMinX(itemFrame) + 100, CGRectGetMidY(itemFrame) + 100, 0, 0);
        if ([item isKindOfClass:[ALGridViewItem class]]) {
            [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
                item.frame = newFrame;
                item.alpha = 0;
            } completion:^(BOOL finished) {
                [item removeFromSuperview];
                [self enqueueReusableItem:item];
                [_items removeObject:item];
                [self removeAndAddItemsIfNecessary];
                [self layoutItemsIsNeedAnimation:YES];
            }];
        }
    } else {
        [self deleteItemAtIndex:index];
    }
}

- (void)deleteItemAtIndex:(NSUInteger)index
{
    ALGridViewItem *item = [_items objectAtIndex:index];
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        if (!item.canDelete) {
            return;
        }
        [item removeFromSuperview];
        [self enqueueReusableItem:item];
        [_items removeObject:item];
        [self removeAndAddItemsIfNecessary];
        [self layoutItemsIsNeedAnimation:YES];
    }
}

- (void)deleteItemAtIndex:(NSUInteger)index animation:(CAAnimation *)animation
{
    if (index > _items.count) {
        return;
    }

    ALGridViewItem *item = [_items objectAtIndex:index];
    if (![item isKindOfClass:[ALGridViewItem class]] || !item.canDelete) {
        return;
    }
    __weak typeof(item) weakItem = item;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_items) weakItems = _items;
    if (animation) {
        [item.layer addAnimation:animation forKey:kDeleteItemAnimationKey];
        CGFloat delaySeconds = animation.duration - 0.05;
        delaySeconds = MAX(delaySeconds, 0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakItem removeFromSuperview];
            [weakItem.layer removeAnimationForKey:kDeleteItemAnimationKey];
            [weakSelf enqueueReusableItem:weakItem];
            [weakItems removeObject:weakItem];
            [weakSelf removeAndAddItemsIfNecessary];
            [weakSelf layoutItemsIsNeedAnimation:YES];
        });
    } else {
        [self deleteItemAtIndex:index];
    }
}

- (BOOL)scrollEnabled
{
    return _contentView.scrollEnabled;
}

- (void)triggerEndEditing:(UITapGestureRecognizer *)gesture
{
    if (_editing && (gesture.state == UIGestureRecognizerStateEnded)) {
        [self endEditing];
    }
}

- (void)setEditing:(BOOL)editing
{
    if (_editing != editing) {
        if (editing) {
            [self beginEditing];
        } else {
            [self endEditing];
        }
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
//    _contentView.delaysContentTouches = NO;
    
    for (ALGridViewItem *item in _items) {
        if ([item isKindOfClass:[NSNull class]]) {
            continue;
        }
        item.editing = YES;
        [item.deleteButton addTarget:self action:@selector(itemDeleteButtonDidTaped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addShakeAnimationForItem:item];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidBeginEditing:)]) {
        [_delegate gridViewDidBeginEditing:self];
    }
}

- (void)addShakeAnimationForItem:(ALGridViewItem *)item
{
    if ([item isKindOfClass:[ALGridViewItem class]]) {
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
}

- (void)removeShakeAnimationForItem:(ALGridViewItem *)item
{
    if (item && [item isKindOfClass:[ALGridViewItem class]]) {
        [item.layer removeAnimationForKey:kShakeAnimationKey];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        [self reloadData];
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
    ALTimerInvalidate(_springTimer)
    ALTimerInvalidate(_triggerEditingHolderTimer)
    [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
        for (ALGridViewItem *item in _items) {
            if ([item isKindOfClass:[NSNull class]]) {
                continue;
            }
            item.deleteButton.alpha = 0;
        
            [self removeShakeAnimationForItem:item];
            
            item.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {
        [self endEditingAnimationDidStop];
        [self layoutItemsIsNeedAnimation:NO];
        [self resetVariatesState];
        if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidEndEditing:)]) {
            [_delegate gridViewDidEndEditing:self];
        }
    }];
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

- (CGRect)visibleRect
{
    return CGRectMake(_contentView.contentOffset.x, _contentView.contentOffset.y, CGRectGetWidth(_contentView.bounds), CGRectGetHeight(_contentView.bounds));
}

- (NSArray *)visibleItems
{
    NSMutableArray *visibleItems = [NSMutableArray array];
    CGRect visibleRect = [self visibleRect];
    BOOL _isFoundFirstItem = NO;
    for (NSInteger index = 0; index < _items.count; index++) {
        ALGridViewItem *item = [_items objectAtIndex:index];
        if ([item isKindOfClass:[ALGridViewItem class]]) {
            CGRect frame = [self frameForItemAtIndex:index];
            if (CGRectIntersectsRect(visibleRect, frame)) {
                if (!_isFoundFirstItem) {
                    _isFoundFirstItem = YES;
                }
                [visibleItems addObject:item];
            } else {
                if (_isFoundFirstItem) {
                    break;
                }
            }
        } else {
            if (_isFoundFirstItem) {
                break;
            }
        }
    }
    return [NSArray arrayWithArray:visibleItems];
}

- (NSArray *)indexsForVisibleItems
{
    NSMutableArray *indexs = [NSMutableArray array];
    CGRect visibleRect = [self visibleRect];
    for (NSInteger index = 0; index < _items.count; index++) {
        ALGridViewItem *item = [_items objectAtIndex:index];
        if ([item isKindOfClass:[ALGridViewItem class]]) {
            CGRect frame = [self frameForItemAtIndex:index];
            if (CGRectIntersectsRect(visibleRect, frame)) {
                [indexs addObject:[NSNumber numberWithInteger:index]];
            }
        }
    }
   
    return [NSArray arrayWithArray:indexs];
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
        [self removeEventsForItem:item];
        if ([item respondsToSelector:@selector(prepareForReuse)]) {
            [item prepareForReuse];
        }
        if ([item.reuseIdentifier length]) {
            if (![_reuseQueue objectForKey:item.reuseIdentifier]) {
                [_reuseQueue setObject:[NSMutableSet set] forKey:item.reuseIdentifier];
            }
            NSMutableSet *set = [_reuseQueue objectForKey:item.reuseIdentifier];
            if ([set count] < kDefaultReuseItemsNumber) {
                [set addObject:item];
            }
        }
        [item removeFromSuperview];
    }
}

- (void)removeEventsForItem:(ALGridViewItem *)item
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

- (void)configEventsForItem:(ALGridViewItem *)item
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
    ALTimerInvalidate(_triggerEditingHolderTimer);
    if (_editing) {
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(gridView:didSelectItemAtIndex:)]) {
        NSInteger index = [self indexOfItem:item];
        if (index != -1) {
            [item setSelected:YES];
            [self performSelector:@selector(deselectItem:) withObject:item afterDelay:0.2];
            [_delegate gridView:self didSelectItemAtIndex:index];
        }
    }
}

- (void)deselectItem:(ALGridViewItem *)item
{
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        item.selected = NO;
    }
}

- (void)itemDidTouchDown:(ALGridViewItem *)item withEvent:(UIEvent *)event
{
    if (!_canEdit) {
        return;
    }
    if (_editing) {
        if (!_dragItem) {
            [self startDragItem:item withEvent:event];
        }
    } else {
        if (_dataSource && [_dataSource respondsToSelector:@selector(gridView:canTriggerEditAtIndex:)]) {
            NSInteger index = [self indexOfItem:item];
            if (index == -1 || index == NSNotFound) {
                return;
            }
            if ([_dataSource gridView:self canTriggerEditAtIndex:index]) {
                [self startTriggerEditingTimerWithTouchItem:item event:event];
            }
        } else {
            [self startTriggerEditingTimerWithTouchItem:item event:event];
        }
    }
}

- (void)startTriggerEditingTimerWithTouchItem:(ALGridViewItem *)item event:(UIEvent *)event
{
    ALTimerInvalidate(_triggerEditingHolderTimer);
    NSDictionary *userInfo = @{kTriggerEditingTimerItemKey:item, kTriggerEditingTimerEventKey:event};
    _triggerEditingHolderTimer = [NSTimer scheduledTimerWithTimeInterval:kEnterEditingHoldInterval target:self selector:@selector(triggerEditingTimerDidFired:) userInfo:userInfo repeats:NO];
}

- (void)triggerEditingTimerDidFired:(NSTimer *)timer
{
    [self beginEditing];
    NSDictionary *userInfo = timer.userInfo;
    ALGridViewItem *item = userInfo[kTriggerEditingTimerItemKey];
    UIEvent *event = userInfo[kTriggerEditingTimerEventKey];
    ALTimerInvalidate(_triggerEditingHolderTimer)
    [self startDragItem:item withEvent:event];
}

- (void)itemDidTouchUpOutSide:(ALGridViewItem *)item
{
    ALTimerInvalidate(_triggerEditingHolderTimer)
}

- (void)itemDeleteButtonDidTaped:(UIButton *)button
{
    ALGridViewItem *item = (ALGridViewItem *)button.superview;
    if ([item isKindOfClass:[ALGridViewItem class]]) {
        if (_delegate && [_delegate respondsToSelector:@selector(gridView:didTapedDeleteButtonWithIndex:)]) {
            [_delegate gridView:self didTapedDeleteButtonWithIndex:item.index];
        }
    }
}

- (void)startDragItem:(ALGridViewItem *)item withEvent:(UIEvent *)event
{
    ALTimerInvalidate(_springTimer)
    if (_dataSource && [_dataSource respondsToSelector:@selector(gridView:canMoveItemAtIndex:)]) {
        NSInteger index = [self indexOfItem:item];
        if (index == -1 || index == NSNotFound) {
            return;
        }
        if (![_dataSource gridView:self canMoveItemAtIndex:index]) {
            return;
        }
    }
    if (item) {
        [self removeShakeAnimationForItem:item];
        item.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [_contentView bringSubviewToFront:item];
        _dragItem = item;
        UITouch *touch = [[event allTouches] anyObject];
        _dragTouch = touch;
//        CGPoint point = [touch locationInView:_contentView];
//        _dragItem.center = point;
        
        if (_delegate && [_delegate respondsToSelector:@selector(gridView:didBeganDragItemAtIndex:)]) {
            NSInteger index = [self indexOfItem:_dragItem];
            [_delegate gridView:self didBeganDragItemAtIndex:index];
        }
    }
}

- (void)updateCreateFolderIfNeed
{
    if (!_canCreateFolder) {
        return;
    }
    CGPoint dragPoint = [_dragTouch locationInView:_contentView];
    CGPoint dragPointInSelf = [_contentView convertPoint:dragPoint toView:self];
//        CGRect dragFrameInSelf = [_contentView convertRect:_dragItem.frame toView:self];
    if (!CGRectContainsPoint(self.bounds, dragPointInSelf)) {
        if (!_dragOutHoldTimer) {
            _dragOutHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kDragOutHoldInterval target:self selector:@selector(dragOutHoldTimerDidFired:) userInfo:nil repeats:NO];
        }
    } else {
        ALTimerInvalidate(_dragOutHoldTimer)
    }
    
    if (_accepterItem) {
        CGRect intersection = CGRectIntersection(_accepterItem.frame, _dragItem.frame);
        BOOL isNeedMerge = (intersection.size.width * intersection.size.height) >= (_accepterItem.frame.size.height * _accepterItem.frame.size.width) * 2.0 / 3.0;
        if (!isNeedMerge) {
            _dragItem.transform = CGAffineTransformMakeScale(1.1, 1.1);
            [self cancelMergeItems];
            ALTimerInvalidate(_didMergeHoldTimer)
        }
    } else {
        BOOL willSpring = NO;
        if (_dragItem) {
            CGRect dragItemFrame = [_contentView convertRect:_dragItem.frame toView:self];
            if (_scrollMode == ALGridViewScrollModeVertical) {
                if (dragItemFrame.origin.y < 0 || CGRectGetMaxY(dragItemFrame) > CGRectGetHeight(self.bounds)) {
                    willSpring = YES;
                }
            } else {
                if (dragItemFrame.origin.x < 0 || CGRectGetMaxX(dragItemFrame) > CGRectGetWidth(self.bounds)) {
                    willSpring = YES;
                }
            }
        }
        if (!willSpring) {
            NSArray *items = [self visibleItems];
            for (NSInteger index = 0; index < items.count; index++) {
                ALGridViewItem *item = [items objectAtIndex:index];
                if (![item isKindOfClass:[ALGridViewItem class]] || [item isEqual:_dragItem]) {
                    continue;
                }
                if (_delegate && [_delegate respondsToSelector:@selector(gridView:canReceiveOtherItemAtIndex:)]) {
                    if (![_delegate gridView:self canReceiveOtherItemAtIndex:[self indexOfItem:item]]) {
                        continue;
                    }
                }
                CGRect intersection = CGRectIntersection(item.frame, _dragItem.frame);
                BOOL isNeedMerge = (intersection.size.width * intersection.size.height) >= ((item.frame.size.height * item.frame.size.width) * 2.0 / 3.0);
                if (isNeedMerge) {
                        if (!_willMergeHoldTimer) {
                            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                            [userInfo setObject:item forKey:kAcceptItemUserInfoKey];
                            _willMergeHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kWillMergeItemHoldInterval target:self selector:@selector(willMergeHoldTimerFired:) userInfo:userInfo repeats:NO];
                            _isHoldTimer = YES;
                            _willReceiverIndex = [self indexOfItem:item];
                        }
                } else {
                    if (_isHoldTimer && ([self indexOfItem:item] == _willReceiverIndex)) {
                        ALTimerInvalidate(_willMergeHoldTimer);
                        _isHoldTimer = NO;
                        _willReceiverIndex = -2;
                        break;
                    }
                }
            }
        }
    }
}

- (void)updateDragTouch
{
    if (!_dragItem) {
        return;
    }
    if (_dataSource && [_dataSource respondsToSelector:@selector(gridView:canMoveItemAtIndex:)]) {
        NSInteger index = [self indexOfItem:_dragItem];
        if (index == -1) {
            return;
        }
        if (![_dataSource gridView:self canMoveItemAtIndex:index]) {
            return;
        }
    }
    CGPoint dragPoint = [_dragTouch locationInView:_contentView];
    _dragItem.center = dragPoint;
    _dragItem.dragging = YES;
    [_contentView bringSubviewToFront:_dragItem];
    
    [self updateCreateFolderIfNeed];
    [self updateSpring];
}

- (void)updateSpring
{
    CGRect dragItemFrameInView = [_contentView convertRect:_dragItem.frame toView:self];
    CGSize itemSize = [self itemSize];
    if (_scrollMode == ALGridViewScrollModeVertical) {
        CGFloat dragItemMaxY = CGRectGetMaxY(dragItemFrameInView);
        CGFloat selfHeight = CGRectGetHeight(self.bounds);
        CGFloat triggerSpringHeight = itemSize.height / 11.0;
        if (dragItemFrameInView.origin.y < 0 && (ABS(dragItemFrameInView.origin.y) >= triggerSpringHeight)) {
            if (_accepterItem) {
                [self cancelMergeItems];
            }
            
            if (!_springTimer) {
                _springTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringHoldInterval target:self selector:@selector(springTimerDidFired:) userInfo:[NSNumber numberWithInt:-1] repeats:NO];
            }
        } else if (dragItemMaxY > selfHeight && ((dragItemMaxY - selfHeight) >= triggerSpringHeight)) {
            if (_accepterItem) {
                [self cancelMergeItems];
            }
            
            if (!_springTimer) {
                _springTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringHoldInterval target:self selector:@selector(springTimerDidFired:) userInfo:[NSNumber numberWithInt:1] repeats:NO];
            }
        } else {
            ALTimerInvalidate(_springTimer)
        }
    } else {
        CGFloat dragMaxX = CGRectGetMaxX(dragItemFrameInView);
        CGFloat selfWidth = CGRectGetWidth(self.bounds);
        CGFloat triggerSpringWidth = itemSize.width / 11.0;
        if (dragItemFrameInView.origin.x < 0 && ABS(dragItemFrameInView.origin.x) >= triggerSpringWidth) {
            if (_accepterItem) {
                [self cancelMergeItems];
            }
            if (!_springTimer) {
                _springTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringHoldInterval target:self selector:@selector(springTimerDidFired:) userInfo:[NSNumber numberWithInt:-1] repeats:NO];
            }
        } else if (dragMaxX > selfWidth && ((dragMaxX - selfWidth) >= triggerSpringWidth)) {
            if (_accepterItem) {
                [self cancelMergeItems];
            }
            if (!_springTimer) {
                _springTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringHoldInterval target:self selector:@selector(springTimerDidFired:) userInfo:[NSNumber numberWithInt:1] repeats:NO];
            }
        } else {
            ALTimerInvalidate(_springTimer)
        }
    }
}

- (void)dragOutHoldTimerDidFired:(NSTimer *)timer
{
    if (_delegate && [_delegate respondsToSelector:@selector(gridView:didDraggedOutItemAtIndex:)]) {
        [_delegate gridView:self didDraggedOutItemAtIndex:[self indexOfItem:_dragItem]];
    }
}

- (void)cancelMergeItems
{
    if (_delegate && [_delegate respondsToSelector:@selector(gridView:didCancelMergeItemsWithReceiverIndex:fromIndex:)]) {
        NSInteger receiveIndex = [self indexOfItem:_accepterItem];
        NSInteger fromIndex = [self indexOfItem:_dragItem];
    
        [_delegate gridView:self didCancelMergeItemsWithReceiverIndex:receiveIndex fromIndex:fromIndex];
    }
    ALTimerInvalidate(_willMergeHoldTimer)
    _accepterItem = nil;
    _isHoldTimer = NO;
    _willReceiverIndex = -2;
}

- (void)willMergeHoldTimerFired:(NSTimer *)timer
{
    NSDictionary *userIndfo = timer.userInfo;
    _accepterItem = [userIndfo valueForKey:kAcceptItemUserInfoKey];
    
    if (_delegate && [_delegate respondsToSelector:@selector(gridView:willMergeItemsWithReceiverIndex:fromIndex:)]) {
        [_delegate gridView:self willMergeItemsWithReceiverIndex:[self indexOfItem:_accepterItem] fromIndex:[self indexOfItem:_dragItem]];
    }
    _dragItem.transform = CGAffineTransformMakeScale(0.9, 0.9);
    _didMergeHoldTimer = [NSTimer scheduledTimerWithTimeInterval:kDidMergeItemHoldInterval target:self selector:@selector(didMergeItemHoldTimerFired:) userInfo:nil repeats:NO];
}

- (void)didMergeItemHoldTimerFired:(NSTimer *)timer
{
    if (_delegate && [_delegate respondsToSelector:@selector(gridView:didMergeItemsWithReceiverIndex:fromIndex:touch:)]) {
            [_delegate gridView:self didMergeItemsWithReceiverIndex:[self indexOfItem:_accepterItem] fromIndex:[self indexOfItem:_dragItem] touch:_dragTouch];
    }
    
    ALTimerInvalidate(_didMergeHoldTimer)
}

- (void)springTimerDidFired:(NSTimer *)timer
{
    int userInfo = [(NSNumber *)timer.userInfo intValue];
    if (userInfo != 1 && userInfo != -1) {
        return;
    }
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    CGPoint offset = _contentView.contentOffset;
    CGPoint offsetCopy = offset;
    if (userInfo == 1) {
        if (_scrollMode == ALGridViewScrollModeVertical) {
            offset.y += selfHeight;
            offset.y = MIN(offset.y, _contentView.contentSize.height - CGRectGetHeight(_contentView.bounds));
        } else {
            offset.x += CGRectGetWidth(_contentView.bounds);
            offset.x = MIN(offset.x, _contentView.contentSize.width - CGRectGetWidth(_contentView.bounds));
        }
        [_contentView setContentOffset:offset animated:YES];
        //当滑动到最后或者最最前一页，继续拖拽，此时_springing为YES，后续无法更新touch事件。
        _springing = YES;
        if (CGPointEqualToPoint(offset, offsetCopy)) {
            _springing = NO;
        }
    } else if (userInfo == -1) {
        if (_scrollMode == ALGridViewScrollModeVertical) {
            offset.y -= selfHeight;
            offset.y = MAX(0, offset.y);
        } else {
            offset.x -= CGRectGetWidth(_contentView.bounds);
            offset.x = MAX(0, offset.x);
        }
        [_contentView setContentOffset:offset animated:YES];
        _springing = YES;
        if (CGPointEqualToPoint(offset, offsetCopy)) {
            _springing = NO;
        }
    }
    ALTimerInvalidate(_springTimer)
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
//    if (_editing) {
//        return ([gestureRecognizer isEqual:_endEditingGesture]) ? (!_dragItem) : NO;
//    }
//    return ![gestureRecognizer isEqual:_endEditingGesture];
    if ([gestureRecognizer isEqual:_endEditingGesture]) {
        if ([touch.view isEqual:self] || [touch.view isEqual:_contentView]) {
            return _editing;
            return _editing && !_dragItem;
        }
        return NO;
    }
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat contentOffset = _contentView.contentOffset.y;
    if (_scrollMode == ALGridViewScrollModeHorizontal) {
        contentOffset = _contentView.contentOffset.x;
    }
    //用户可能在contentOffset为0的时候，向上/左 拖拽
    if (contentOffset > 0) {
        CGFloat diff = 0;
#if __LP64__
        diff = fabs(_lastOffsetY - contentOffset);
#else
        diff = fabsf(_lastOffsetY - contentOffset);
#endif
        if (diff > _offsetThreshold) {
            _lastOffsetY = contentOffset;
            [self removeAndAddItemsIfNecessary];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidScroll:)]) {
        [_delegate gridViewDidScroll:self];
    }
}

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//     NSLog(@"%s", __FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewWillBeginDragging:)]) {
        [_delegate gridViewWillBeginDragging:self];
    }
}

//// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//    NSLog(@"%s", __FUNCTION__);
//    NSLog(@"%@", NSStringFromCGPoint(velocity));
//}

// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
//    ALTimerInvalidate(_triggerEditingHolderTimer)
//    if (_dragItem) {
//        NSInteger index = [self indexOfItem:_dragItem];
//        if (index == -1) {
//            return;
//        }
//        CGRect frame = [self frameForItemAtIndex:index];
//        _dragItem.frame = frame;
//        _dragItem = nil;
//    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidEndDragging:willDecelerate:)]) {
        [_delegate gridViewDidEndDragging:self willDecelerate:decelerate];
    }
}

// called on finger up as we are moving，手指离开屏幕，视图继续滚动的时候
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
//     NSLog(@"%s", __FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewWillBeginDecelerating:)]) {
        [_delegate gridViewWillBeginDecelerating:self];
    }
}

// called when scroll view grinds to a halt,停止滑动了
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    NSLog(@"%s", __FUNCTION__);
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidEndDecelerating:)]) {
        [_delegate gridViewDidEndDecelerating:self];
    }
}

// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (_dragItem) {
        _springing = NO;
        CGPoint center = _dragItem.center;
        center.y += CGRectGetHeight(self.bounds);
        _dragItem.center = center;
        [self updateDragTouch];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidEndScrollingAnimation:)]) {
        [_delegate gridViewDidEndScrollingAnimation:self];
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self resetAllVisibleItems]; //是否必须
    if (_delegate && [_delegate respondsToSelector:@selector(gridViewDidScrollToTop:)]) {
        [_delegate gridViewDidScrollToTop:self];
    }
}

#pragma mark - Touch Action
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (_dragItem && !_springing) {
        for (UITouch *touch in touches) {
            if ([touch isEqual:_dragTouch]) {
                [self updateDragTouch];
                break;
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    [self endTouch:touches];
}

- (void)endTouch:(NSSet *)touches
{
    ALTimerInvalidate(_springTimer)
    ALTimerInvalidate(_triggerEditingHolderTimer)
    _springing = NO;
    if (_dragItem) {
        _dragItem.transform = CGAffineTransformIdentity;
        [self addShakeAnimationForItem:_dragItem];
        _dragItem.dragging = NO;
        if (_delegate && [_delegate respondsToSelector:@selector(gridView:didEndDragItemAtIndex:)]) {
            NSInteger index = [self indexOfItem:_dragItem];
            if (index != -1) {
                [_delegate gridView:self didEndDragItemAtIndex:index];
            }
        }
        
        ALTimerInvalidate(_willMergeHoldTimer)
        if (_didMergeHoldTimer) {
            [self cancelMergeItems];
        }
        ALTimerInvalidate(_didMergeHoldTimer)
        _dragItem = nil;
    }
    for (UITouch *touch in touches) {
        if ([touch isEqual:_dragTouch]) {
            _dragTouch = nil;
            break;
        }
    }
    [self layoutItemsIsNeedAnimation:YES];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    [self endTouch:touches];
}

@end
