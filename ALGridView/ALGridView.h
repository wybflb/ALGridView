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
    ALGridViewScrollModeVertical, /** 垂直滚动*/
    ALGridViewScrollModeHorizontal, /** 横向滚动*/
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
@property (nonatomic, assign) BOOL canEnterEditing; /**< 是否可进入编辑状态，默认为YES*/
@property (nonatomic, getter = isEditing, assign) BOOL editing;
@property (nonatomic, assign) ALGridViewScrollMode scrollMode; //the default value is ALGridViewScrollModeVertical

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
 @return 包含所有可见item的index数组，数组对象为NSNumber类型，数值为对应的index值，如果没有可见item，返回空数组。
 */
- (NSArray *)indexsForVisibleItems;

- (CGRect)frameForItemAtIndex:(NSInteger)index;

@end

@protocol ALGridViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInGridView:(ALGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(ALGridView *)gridView;
- (ALGridViewItem *)ALGridView:(ALGridView *)gridView itemAtIndex:(NSInteger)index;
@optional
- (BOOL)ALGridView:(ALGridView *)gridView canMoveItemAtIndex:(NSInteger)index;
- (BOOL)ALGridView:(ALGridView *)gridView canTriggerEditAtIndex:(NSInteger)index;
@end

@protocol ALGridViewDelegate <NSObject>
@required
- (CGSize)itemSizeForGridView:(ALGridView *)gridView;
@optional
- (void)ALGridView:(ALGridView *)gridView didSelectItemAtIndex:(NSInteger)index;
- (CGFloat)rowSpacingForGridView:(ALGridView *)gridView;
- (CGFloat)columnSpacingForGridView:(ALGridView *)gridView;
- (void)ALGridView:(ALGridView *)gridView didDraggedOutItemAtIndex:(NSInteger)index;
- (void)ALGridView:(ALGridView *)gridView didDraggedItemAtIndex:(NSInteger)sourceIndex intoItemAtIndex:(NSInteger)destinationIndex withTouch:(UITouch *)touch;
- (void)ALGridViewDidBeginEditing:(ALGridView *)gridView;
- (void)ALGridViewDidEndEditing:(ALGridView *)gridView;
- (void)ALGridView:(ALGridView *)gridView scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)ALGridView:(ALGridView *)gridView didTapedDeleteButtonWithIndex:(NSInteger)index;
- (void)ALGridView:(ALGridView *)gridView didBeganDragItemAtIndex:(NSInteger)index;
- (void)ALGridView:(ALGridView *)gridView didEndDragItemAtIndex:(NSInteger)index;

- (void)ALGridViewDidScroll:(ALGridView *)gridView;
- (void)ALGridViewDidScrollToTop:(ALGridView *)gridView;
@end