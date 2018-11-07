//
//  DMPickView.m
//  DuoMiPro
//
//  Created by yollet on 2018/7/6.
//  Copyright © 2018年 yollet. All rights reserved.
//

#import "DMPickView.h"

@implementation DMPickView

- (instancetype)initWithFrame:(CGRect)frame dataArray:(NSArray *)dataArray pickBlock:(PickBlock)block
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.fitX = [UIScreen mainScreen].bounds.size.width / 375.0;
        self.fitY = [UIScreen mainScreen].bounds.size.height / 667.0;
        self.isX = NO;
        self.topHeight = 0;
        self.bottomHeight = 0;
        if ([UIScreen mainScreen].bounds.size.height == 812 || [UIScreen mainScreen].bounds.size.height == 896) {
            self.topHeight = 24;
            self.bottomHeight = 34;
            self.fitY = 1;
            self.isX = YES;
        }
        if ([UIScreen mainScreen].bounds.size.height == 896) {
            self.fitY = _fitX;
        }
        
        self.pickBlock = block;
        self.dataArray = dataArray;
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
        
        UIView *pickBackView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - _bottomHeight - 250 * _fitY, frame.size.width, 250 * _fitY)];
        pickBackView.backgroundColor = [UIColor whiteColor];
        [self addSubview:pickBackView];
        
        self.pickView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 30 * _fitY, pickBackView.frame.size.width, pickBackView.frame.size.height - 30 * _fitY)];
        self.pickView.delegate = self;
        self.pickView.dataSource = self;
        self.pickView.showsSelectionIndicator = YES;
        [pickBackView addSubview:_pickView];
        
        UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 30 * _fitY)];
        topView.backgroundColor = [UIColor colorWithRed:246 / 255.0 green:249 / 255.0 blue:1 alpha:1];
        [pickBackView addSubview:topView];
        
        self.hidButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.hidButton.frame = CGRectMake(CGRectGetMaxX(topView.frame) - 20 * _fitX - 50, 0, 50, 30 * _fitY);
//        [self.hidButton setBackgroundColor:[UIColor cyanColor]];
        [self.hidButton setTitle:@"完成" forState:UIControlStateNormal];
        [self.hidButton setTitleColor:[UIColor colorWithRed:77 / 255.0 green:131 / 255.0 blue:1 alpha:1] forState:UIControlStateNormal];
        [self.hidButton addTarget:self action:@selector(hidAction:) forControlEvents:UIControlEventTouchUpInside];
        [topView addSubview:_hidButton];
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _dataArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _dataArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (_pickBlock) {
        self.pickBlock(row, _dataArray[row]);
    }
}

- (void)tapAction:(UITapGestureRecognizer *)tap
{
//    [self removeFromSuperview];
    self.hidden = YES;
}

- (void)hidAction:(UIButton *)button
{
//    [self removeFromSuperview];
    self.hidden = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
