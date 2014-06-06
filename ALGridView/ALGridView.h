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

@interface ALGridView : UIView

@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, assign) id<ALGridViewDataSource>dataSource;
@property (nonatomic, assign) id<ALGridViewDelegate>delegate;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, assign) CGFloat leftMargin;
@property (nonatomic, readonly) BOOL scrollEnabled;
@property (nonatomic, getter = isEditing) BOOL editing;

- (void)reloadData;
- (ALGridViewItem *)itemAtIndex:(NSInteger)index;
- (NSInteger)indexOfItem:(ALGridViewItem *)item;
- (ALGridViewItem *)dequeueReusableItemWithIdentifier:(NSString *)reuseIdentifier;
- (void)deleteItemAtIndex:(NSInteger)index;
- (void)deleteItemAtIndex:(NSInteger)index animation:(CAAnimation *)animation;
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

- (void)ALGridViewDidScroll:(ALGridView *)gridView;
- (void)ALGridViewDidScrollToTop:(ALGridView *)gridView;
@end