
//  SignViewController.m
//  移动签章
//
//  Created by 番茄 on 2018/1/23.
//  Copyright © 2018年 番茄. All rights reserved.
//

#import "SignViewController.h"
#import "SignaturePDF.h"
@interface SignViewController ()<UIWebViewDelegate,UIScrollViewDelegate>
@property (strong, nonatomic) UIWebView *webView;
//签名图片
@property (nonatomic,strong)  UIImageView * signIV;

//PDF原大小
@property (nonatomic,assign) CGFloat PDFWidth;
@property (nonatomic,assign) CGFloat PDFHeight;

//签名图片坐标x、y
@property (nonatomic,assign)  CGFloat signIV_X;
@property (nonatomic,assign)  CGFloat signIV_Y;

//签名图片坐标x、y
@property (nonatomic,assign)  CGPoint contentOffset;
@property (nonatomic,assign)  CGSize contentSize;

//宽高比系数
@property (nonatomic,assign) CGFloat scaleX;
@property (nonatomic,assign) CGFloat scaleY;
//放大系数
@property (nonatomic,assign) CGFloat scroScale;
@end

#define pdfPath [NSTemporaryDirectory() stringByAppendingString:@"sign.pdf"]
@implementation SignViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    //webview加载PDF
    _webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.showsHorizontalScrollIndicator = NO;
    [_webView setScalesPageToFit:YES];
    _webView.delegate = self;
    _webView.scrollView.delegate = self;
    _webView.scrollView.maximumZoomScale = 5.0;
    [self.view addSubview:_webView];
//       _signImage = [UIImage imageNamed:@"logo.jpg"];
    //在pdf上加载 签名图片
    _signIV= [[UIImageView alloc]initWithFrame:CGRectMake(5, 7, 60, 30)];
    _signIV.image = self.signImage;
    _signIV.backgroundColor = [UIColor yellowColor];
    [_webView addSubview:_signIV];
    //添加拖拽手势  可以吧签名图片放到想要的位置
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [_signIV setUserInteractionEnabled:YES];//开启图片控件的用户交互
    [_signIV addGestureRecognizer:pan];//给图片添加手势
    
    //生成签名的PDF图片
    UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 50, 50);
    [button addTarget:self action:@selector(signName) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"签名的" forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem =  [[UIBarButtonItem alloc] initWithCustomView:button];
    [self initData];
}

-(void)initData{
    //加载本地pdf
//    NSString * file =@"/Users/fanqie/Desktop/instance.pdf";
    NSString * file = [[NSBundle mainBundle]pathForResource:@"instance"ofType:@"pdf"];
    NSData * data  = [NSData dataWithContentsOfFile:file];
    [data writeToFile:pdfPath atomically:YES];
    
    NSURL *filePath = [NSURL fileURLWithPath:pdfPath];
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:filePath];
    [_webView loadRequest:request];
    
    //读取PDF原文件的大小
    CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)filePath);
    CGPDFPageRef page = CGPDFDocumentGetPage(doc, 1);
    CGRect mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    NSLog(@"#mediaBox: %@",NSStringFromCGRect(mediaBox));
    
    self.PDFWidth  = [self floatWithdecimalNumber:mediaBox.size.width];
    self.PDFHeight = [self floatWithdecimalNumber:mediaBox.size.height];
}

#pragma mark scrollViewDelegete
// scrollView 结束拖动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.contentOffset = scrollView.contentOffset;
    self.contentSize = scrollView.contentSize;
    [self reloadSignPicturePoint:scrollView.contentOffset contentSize:scrollView.contentSize];
    NSLog(@"%@",NSStringFromCGPoint(scrollView.contentOffset));
}
// scrollview 减速停止
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.contentOffset = scrollView.contentOffset;
    self.contentSize = scrollView.contentSize;
    [self reloadSignPicturePoint:scrollView.contentOffset contentSize:scrollView.contentSize];
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    self.contentOffset = scrollView.contentOffset;
    self.contentSize = scrollView.contentSize;
    self.scroScale = scale;
    [self reloadSignPicturePoint:scrollView.contentOffset contentSize:scrollView.contentSize];
    NSLog(@"变化 %.2f",scale);
}

//签名
-(void)signName{
    //传入签名图片坐标  保存签名后的pdf路径。备注：这个(400, 145, 50, 20)坐标能签到准确位置
//    NSString * savePath = @"/Users/fanqie/Desktop/instance.pdf";
    NSString * savePath = pdfPath;
    [SignaturePDF addSignature:_signImage onPDFFilePath:savePath drawRect:CGRectMake(_signIV_X, _signIV_Y,60 * self.scaleX, 30 * self.scaleY)];
    [_webView reload];
    [_signIV removeFromSuperview];
}

//刷新坐标
-(void)reloadSignPicturePoint:(CGPoint)contentOffSet  contentSize:(CGSize)contentSize{
    //放大后的偏移量
    CGFloat x = contentOffSet.x + _signIV.frame.origin.x;
    CGFloat y = contentOffSet.y + CGRectGetMaxY(_signIV.frame) - 7*self.scroScale;
    
    if (contentSize.width == 0 && contentSize.height == 0) {
        contentSize = self.webView.scrollView.contentSize;
    }

    //宽高比例系数
    _scaleX = 0.0;
    _scaleY = 0.0;
  
    
    _scaleX = [self floatWithdecimalNumber:(_PDFWidth + 5*self.scroScale)/contentSize.width];
    //x轴上误差为±2
    self.signIV_X = x*_scaleX;
    
    _scaleY = [self floatWithdecimalNumber:(_PDFHeight + 7*self.scroScale)/contentSize.height];
    
    //y轴上误差为随着y坐标的增大而减小
    self.signIV_Y = _PDFHeight - y*_scaleY - 3;
 
    NSLog(@"%.2f----%.2f",self.signIV_X,self.signIV_Y);
}




- (float)floatWithdecimalNumber:(double)num {
    return [[self decimalNumber:num] doubleValue];
}
- (NSDecimalNumber *)decimalNumber:(double)num {
    NSString *numString = [NSString stringWithFormat:@"%.2f", num];
    return [NSDecimalNumber decimalNumberWithString:numString];
}




#pragma mark - 手势执行的方法
-(void)handlePan:(UIPanGestureRecognizer *)rec{
    
    CGFloat KWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat KHeight = [UIScreen mainScreen].bounds.size.height;
    
    //返回在横坐标上、纵坐标上拖动了多少像素
    CGPoint point=[rec translationInView:self.view];
    
    CGFloat centerX = rec.view.center.x+point.x;
    CGFloat centerY = rec.view.center.y+point.y;
    
    CGFloat viewHalfH = rec.view.frame.size.height/2;
    CGFloat viewhalfW = rec.view.frame.size.width/2;
    
    //确定特殊的centerY
    if (centerY - viewHalfH < 0 ) {
        centerY = viewHalfH;
    }
    if (centerY + viewHalfH > KHeight ) {
        centerY = KHeight - viewHalfH;
    }
    
    //确定特殊的centerX
    if (centerX - viewhalfW < 0){
        centerX = viewhalfW;
    }
    if (centerX + viewhalfW > KWidth){
        centerX = KWidth - viewhalfW;
    }
    
    rec.view.center=CGPointMake(centerX, centerY);
    
    //拖动完之后，每次都要用setTranslation:方法制0这样才不至于不受控制般滑动出视图
    [rec setTranslation:CGPointMake(0, 0) inView:self.view];
    
    switch (rec.state) {
        case UIGestureRecognizerStateBegan:
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            break;
            
        case UIGestureRecognizerStateEnded:
            [self reloadSignPicturePoint:self.contentOffset contentSize:self.contentSize];
            break;
            
        case UIGestureRecognizerStateCancelled:
            
            break;
            
        case UIGestureRecognizerStateFailed:
            NSLog(@"-----Current State: Failed-----");
            NSLog(@"Failed events");
            break;
        default:
            break;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
