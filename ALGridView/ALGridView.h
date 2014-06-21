//
//  ALGridView.h
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALGridViewItem.h"

@protocol ALGridViewDataSource;
@protocol ALGridViewDelegate;

typedef NS_ENUM(NSInteger, ALGridViewScrollMode) {
    ALGridViewScrollModeVertical, /**< 垂直滚动*/
    ALGridViewScrollModeHorizontal, /**< 横向滚动*/
};

@interface ALGridView : UIView
{
    BOOL _editing;
}

@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, assign) id<ALGridViewDataSource>dataSource;
@property (nonatomic, assign) id<ALGridViewDelegate>delegate;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat leftMargin;
@property (nonatomic, readonly) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL canEdit; /**< 是否可进入编辑状态，默认为YES*/
@property (nonatomic, getter = isEditing, assign) BOOL editing;
@property (nonatomic, assign) ALGridViewScrollMode scrollMode; //the default value is ALGridViewScrollModeVertical
@property (nonatomic, assign) BOOL canCreateFolder; //是否支持编辑状态合并两个item，创建文件夹，默认为NO。

- (void)reloadData;
- (ALGridViewItem *)itemAtIndex:(NSUInteger)index;
- (NSInteger)indexOfItem:(ALGridViewItem *)item;
- (ALGridViewItem *)dequeueReusableItemWithIdentifier:(NSString *)reuseIdentifier;
- (void)deleteItemAtIndex:(NSUInteger)index isNeedAnimation:(BOOL)needAnimation;
- (void)deleteItemAtIndex:(NSUInteger)index animation:(CAAnimation *)animation;
- (NSInteger)numberOfPagesForHorizontalScroll;

- (NSArray *)visibleItems;
/**
 返回当前可见的items所有的index
 @return 包含所有可见item的index数组，数组对象为NSNumber类型，数值为对应的index的Integer值，如果没有可见item，返回空数组。
 */
- (NSArray *)indexsForVisibleItems;

- (CGRect)frameForItemAtIndex:(NSInteger)index;

@end

@protocol ALGridViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInGridView:(ALGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(ALGridView *)gridView;
- (ALGridViewItem *)gridView:(ALGridView *)gridView itemAtIndex:(NSInteger)index;
@optional
- (BOOL)gridView:(ALGridView *)gridView canMoveItemAtIndex:(NSInteger)index;
- (BOOL)gridView:(ALGridView *)gridView canTriggerEditAtIndex:(NSInteger)index;
@end

@protocol ALGridViewDelegate <NSObject>
@required
- (CGSize)itemSizeForGridView:(ALGridView *)gridView;
@optional
- (void)gridView:(ALGridView *)gridView didSelectItemAtIndex:(NSInteger)index;//
- (CGFloat)rowSpacingForGridView:(ALGridView *)gridView;//
- (CGFloat)columnSpacingForGridView:(ALGridView *)gridView;//

- (void)gridViewDidBeginEditing:(ALGridView *)gridView;//
- (void)gridViewDidEndEditing:(ALGridView *)gridView;//

- (void)gridViewDidScroll:(ALGridView *)gridView;//
- (void)gridViewWillBeginDragging:(ALGridView *)gridView;//
- (void)gridViewDidEndDragging:(ALGridView *)gridView willDecelerate:(BOOL)decelerate;//
- (void)gridViewWillBeginDecelerating:(ALGridView *)gridView;//
- (void)gridViewDidEndDecelerating:(ALGridView *)gridView;//
- (void)gridViewDidEndScrollingAnimation:(ALGridView *)gridView;//
- (void)gridViewDidScrollToTop:(ALGridView *)gridView;//

- (void)gridView:(ALGridView *)gridView didBeganDragItemAtIndex:(NSInteger)index;//
- (void)gridView:(ALGridView *)gridView didEndDragItemAtIndex:(NSInteger)index;//

- (void)gridView:(ALGridView *)gridView willMergeItemsWithReceiverIndex:(NSInteger)receiverIndex fromIndex:(NSInteger)fromIndex;//
- (void)gridView:(ALGridView *)gridView didCancelMergeItemsWithReceiverIndex:(NSInteger)receiverIndex fromIndex:(NSInteger)fromIndex;//
- (void)gridView:(ALGridView *)gridView didMergeItemsWithReceiverIndex:(NSInteger)receiverIndex fromIndex:(NSInteger)fromIndex touch:(UITouch *)touch;//
- (BOOL)gridView:(ALGridView *)gridView canReceiveOtherItemAtIndex:(NSInteger)index;//

- (void)gridView:(ALGridView *)gridView didDraggedOutItemAtIndex:(NSInteger)index;

- (void)gridView:(ALGridView *)gridView didTapedDeleteButtonWithIndex:(NSInteger)index;

@end