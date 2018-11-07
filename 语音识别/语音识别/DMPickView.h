//
//  DMPickView.h
//  DuoMiPro
//
//  Created by yollet on 2018/7/6.
//  Copyright © 2018年 yollet. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PickBlock)(NSInteger row, NSString *data);

@interface DMPickView : UIView <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, copy) PickBlock pickBlock;
@property (nonatomic, strong) UIPickerView *pickView;
@property (nonatomic, strong) UIButton *hidButton;
@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, assign) CGFloat fitX;
@property (nonatomic, assign) CGFloat fitY;
@property (nonatomic, assign) BOOL isX;
@property (nonatomic, assign) CGFloat topHeight;
@property (nonatomic, assign) CGFloat bottomHeight;


- (instancetype)initWithFrame:(CGRect)frame dataArray:(NSArray *)dataArray pickBlock:(PickBlock)block;

@end
