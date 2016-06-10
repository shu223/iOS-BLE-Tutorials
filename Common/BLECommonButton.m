//
//  BLECommonButton.m
//
//  Created by Shuichi Tsutsumi on 2015/01/25.
//  Copyright (c) 2015 Shuichi Tsutsumi. All rights reserved.
//

#import "BLECommonButton.h"
#import "BLEAppearance.h"


@interface UIImage (TTMExtentions)

+ (UIImage *)imageOfSize:(CGSize)size color:(UIColor *)color;

@end


@implementation UIImage (TTMExtentions)

+ (UIImage *)imageOfSize:(CGSize)size color:(UIColor *)color {
    
    UIGraphicsBeginImageContext(size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGRect fillRect = CGRectMake(0,0,size.width,size.height);
    CGContextSetFillColorWithColor(currentContext, color.CGColor);
    CGContextFillRect(currentContext, fillRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end


@implementation BLECommonButton

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.backgroundColor = BLE_MAIN_COLOR;
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 0.5;
    self.layer.cornerRadius = 4.0;
    self.layer.masksToBounds = YES;
    
    UIImage *bgImage1 = [UIImage imageOfSize:CGSizeMake(1, 1) color:BLE_MAIN_COLOR];
    UIImage *bgImage2 = [UIImage imageOfSize:CGSizeMake(1, 1) color:[UIColor whiteColor]];

    [self setBackgroundImage:bgImage1 forState:UIControlStateNormal];
    [self setBackgroundImage:bgImage2 forState:UIControlStateHighlighted];
    
    [self setTitleColor:BLE_HIGHLIGHTED_COLOR forState:UIControlStateHighlighted];
}

@end
