//
//  ALGridViewCell.h
//  ALGridView
//
//  Created by Arien Lau on 14-5-27.
//  Copyright (c) 2014年 Arien Lau. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ALGridViewCell : UIControl

@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, getter = isDragging) BOOL dragging;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, assign) BOOL canDelete;
@property (nonatomic, assign) BOOL canMove;
@property (nonatomic, assign) BOOL canTriggerEdit;
@property (nonatomic, assign) BOOL canLeaveCurrentView;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, retain) UIButton *deleteButton;

- (ALGridViewCell *)initWithReuseIdentifier:(NSString *)identifier;
- (void)prepareForReuse;
/**
 是否可以接收其他cell进入，创建一个文件夹
 @param otherCell 被拖入的cell
 @param touch 当前touch对象
 */
- (BOOL)canReceiveOtherCellIn:(ALGridViewCell *)otherCell withTouch:(UITouch *)touch;

@end
