//
//  SignaturePDF.m
//  PDF
//
//  Created by 番茄 on 2017/11/16.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import "SignaturePDF.h"
#import <CoreText/CoreText.h>

@implementation SignaturePDF


+(void)addSignature:(id)obj onPDFFilePath:(NSString *)filePath drawRect:(CGRect)pageRect{
    NSData * pdfData  = [NSData dataWithContentsOfFile:filePath];
    NSMutableData * outputPDFData = [[NSMutableData alloc] init];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)outputPDFData);
    
    CFMutableDictionaryRef attrDictionary  =  NULL;
    attrDictionary = CFDictionaryCreateMutable(NULL,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrDictionary,kCGPDFContextTitle,CFSTR("My Doc"));
    
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer,NULL,attrDictionary);
    CFRelease(dataConsumer);
    CFRelease(attrDictionary);
    
    
    // Draw the old "pdfData" on pdfContext
    CFDataRef myPDFData = (__bridge CFDataRef)pdfData;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    
    CGPDFPageRef page =CGPDFDocumentGetPage(pdf,1);
    CGRect PDFRect= CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGContextBeginPage(pdfContext,&PDFRect);
    CGContextDrawPDFPage(pdfContext,page);
    
    // Draw the image signature on pdfContext
    if ([obj isKindOfClass:[UIImage class]]) {
        UIImage * imgSignature = (UIImage*)obj;
        CGImageRef pageImage = [imgSignature CGImage];
        CGContextDrawImage(pdfContext,pageRect,pageImage);
    }
    
    
    // Draw the string signature on pdfConte
    if ([obj isKindOfClass:[NSString class]]) {
        NSString * string =(NSString*)obj;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, pageRect);
        NSAttributedString* attString =  [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:[UIFont fontWithName:FONTNAME size:FONTSIZE]}];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attString.length), path, NULL);
        CTFrameDraw(frame, pdfContext);
        CFRelease(framesetter);
        CFRelease(path); CFRelease(frame);
    }
    
    // release the allocated memory
    CGPDFContextEndPage(pdfContext);
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
    CGPDFPageRelease(page);
    // write new PDFData in "outPutPDF.pdf" file in document directory
//    NSString * docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//    NSString * pdfFilePath = [NSString stringWithFormat:@"%@/outPutPDF.pdf",docsDirectory];
    [outputPDFData writeToFile:filePath atomically:YES];
    
}


-(void)getPDF{
    
    // 1.创建media box
//    CGFloat myPageWidth = self.view.bounds.size.width;
//    CGFloat myPageHeight = self.view.bounds.size.height;
    CGFloat myPageWidth = 0;
    CGFloat myPageHeight = 0;
    CGRect mediaBox = CGRectMake (0, 0, myPageWidth, myPageHeight);
    
    // 2.设置pdf文档存储的路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *filePath = [documentsDirectory stringByAppendingString:@"/test.pdf"];
    // NSLog(@"%@", filePath);
    const char *cfilePath = [filePath UTF8String];
    CFStringRef pathRef = CFStringCreateWithCString(NULL, cfilePath, kCFStringEncodingUTF8);
    
    
    // 3.设置当前pdf页面的属性
    CFStringRef myKeys[3];
    CFTypeRef myValues[3];
    myKeys[0] = kCGPDFContextMediaBox;
    myValues[0] = (CFTypeRef) CFDataCreate(NULL,(const UInt8 *)&mediaBox, sizeof (CGRect));
    myKeys[1] = kCGPDFContextTitle;
    myValues[1] = CFSTR("我的PDF");
    myKeys[2] = kCGPDFContextCreator;
    myValues[2] = CFSTR("Jymn_Chen");
    CFDictionaryRef pageDictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,&kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    
    
    // 4.获取pdf绘图上下文
    CGContextRef myPDFContext = MyPDFContextCreate (&mediaBox, pathRef);
    
    
    // 5.开始描绘第一页页面
    CGPDFContextBeginPage(myPDFContext, pageDictionary);
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 为一个矩形设置URL链接www.baidu.com
    CFURLRef baiduURL = CFURLCreateWithString(NULL, CFSTR("http://www.baidu.com"), NULL);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, baiduURL, CGRectMake (200, 200, 100, 200 ));
    
    // 为一个矩形设置一个跳转终点
    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page"), CGPointMake(120.0, 400.0));
    CGPDFContextSetDestinationForRect(myPDFContext, CFSTR("page"), CGRectMake(50.0, 300.0, 100.0, 100.0)); // 跳转点的name为page
    //    CGPDFContextSetDestinationForRect(myPDFContext, CFSTR("page2"), CGRectMake(50.0, 300.0, 100.0, 100.0)); // 跳转点的name为page2
    CGContextSetRGBFillColor(myPDFContext, 1, 0, 1, 0.5);
    CGContextFillEllipseInRect(myPDFContext, CGRectMake(50.0, 300.0, 100.0, 100.0));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    // 6.开始描绘第二页页面
    // 注意要另外创建一个page dictionary
    CFDictionaryRef page2Dictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,&kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGPDFContextBeginPage(myPDFContext, page2Dictionary);
    
    // 在左下角画两个矩形
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 在右下角写一段文字:"Page 2"
    CGContextSelectFont(myPDFContext, "Helvetica", 30, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode (myPDFContext, kCGTextFill);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    const char *text = [@"Page 2" UTF8String];
    CGContextShowTextAtPoint (myPDFContext, 120, 80, text, strlen(text));
    //    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page2"), CGPointMake(120.0, 120.0));  // 跳转点的name为page2
    //    CGPDFContextAddDestinationAtPoint(myPDFContext, CFSTR("page"), CGPointMake(120.0, 120.0)); // 跳转点的name为page
    
    // 为右上角的矩形设置一段file URL链接，打开本地文件
    NSURL *furl = [NSURL fileURLWithPath:@"/Users/fanqie/Desktop/testPDF.pdf"];
    CFURLRef fileURL = (__bridge CFURLRef)furl;
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, fileURL, CGRectMake (200, 200, 100, 200 ));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    // 7.创建第三页内容
    CFDictionaryRef page3Dictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,&kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGPDFContextBeginPage(myPDFContext, page3Dictionary);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGPDFContextEndPage(myPDFContext);
    
    
    // 8.释放创建的对象
    CFRelease(page3Dictionary);
    CFRelease(page2Dictionary);
    CFRelease(pageDictionary);
    CFRelease(myValues[0]);
    CGContextRelease(myPDFContext);
    CFRelease(baiduURL);
    
}

/*
 * 获取pdf绘图上下文
 * inMediaBox指定pdf页面大小
 * path指定pdf文件保存的路径
 */
CGContextRef MyPDFContextCreate (const CGRect *inMediaBox, CFStringRef path)
{
    CGContextRef myOutContext = NULL;
    CFURLRef url;
    CGDataConsumerRef dataConsumer;
    
    url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, false);
    
    if (url != NULL)
    {
        dataConsumer = CGDataConsumerCreateWithURL(url);
        if (dataConsumer != NULL)
        {
            myOutContext = CGPDFContextCreate (dataConsumer, inMediaBox, NULL);
            CGDataConsumerRelease (dataConsumer);
        }
        CFRelease(url);
    }
    return myOutContext;
}
@end
