//
//  SignaturePDF.h
//  PDF
//
//  Created by 番茄 on 2017/11/16.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
// 文字大小、文字属性
#define FONTSIZE  40
#define FONTNAME  @"PingFangHK-Regular"

@interface SignaturePDF : NSObject
/*
 * obj  要写在pdf上的数据：如图片、文字
 * filePath  pdf文件路径
 * rect  写入位置
 */
+(void)addSignature:(id)obj onPDFFilePath:(NSString *)filePath drawRect:(CGRect)pageRect;
@end
