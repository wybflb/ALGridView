//
//  ALGridView.h
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALGridViewCell.h"

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
- (ALGridViewCell *)gridViewCellAtIndex:(NSInteger)index;
- (NSInteger)numberOfItemsInGridView:(ALGridView *)gridView;
- (ALGridViewCell *)dequeueReusableItemWithIdentifier:(NSString *)reuseIdentifier;

@end

@protocol ALGridViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInGridView:(ALGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(ALGridView *)gridView;
- (ALGridViewCell *)ALGridView:(ALGridView *)gridView cellAtIndex:(NSInteger)index;
@optional
- (BOOL)ALGridView:(ALGridView *)gridView canMoveItemAtIndex:(NSInteger)index;
- (BOOL)ALGridView:(ALGridView *)gridView canTriggerEditAtIndex:(NSInteger)index;
@end

@protocol ALGridViewDelegate <NSObject>
@required
- (CGSize)itemSizeForGridView:(ALGridView *)gridView;
- (void)ALGridView:(ALGridView *)gridView didSelectItemAtIndex:(NSInteger)index;
@optional
- (CGFloat)rowSpacingForGridView:(ALGridView *)gridView;
- (CGFloat)columnSpacingForGridView:(ALGridView *)gridView;
- (void)ALGridView:(ALGridView *)gridView didDraggedOutCellAtIndex:(NSInteger)index;
- (void)ALGridView:(ALGridView *)gridView didDraggedCellAtIndex:(NSInteger)sourceIndex intoCellAtIndex:(NSInteger)destinationIndex withTouch:(UITouch *)touch;
- (void)ALGridViewDidEndEditing:(ALGridView *)gridView;
- (void)ALGridView:(ALGridView *)gridView scrollViewDidScroll:(UIScrollView *)scrollView;
@end