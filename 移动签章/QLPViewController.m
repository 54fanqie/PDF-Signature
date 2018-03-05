//
//  QLPViewController.m
//  移动签章
//
//  Created by 番茄 on 2/2/18.
//  Copyright © 2018 番茄. All rights reserved.
//

#import "QLPViewController.h"
#import "SignaturePDF.h"
@interface QLPViewController ()<QLPreviewControllerDelegate,QLPreviewControllerDataSource,UIScrollViewDelegate>
@property(nonatomic,strong) QLPreviewController * qLController ;
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
@implementation QLPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    //设置navigationBar不透明防止设置UIRectEdgeNone后，背景变暗
    self.navigationController.navigationBar.translucent = NO;
    
    //生成签名的PDF图片
    UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 50, 50);
    [button addTarget:self action:@selector(signName) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"生成签名" forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem =  [[UIBarButtonItem alloc] initWithCustomView:button];
    
    
    // 将QLPreviewControler  添加到本控制器上
    self.qLController= [[QLPreviewController alloc] init];
    self.qLController.dataSource = self;
    self.qLController.delegate = self;
    [self addChildViewController:self.qLController];
    [self.qLController didMoveToParentViewController:self];
    [self.view addSubview:self.qLController.view];
    self.qLController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    
    //添加签名图片
    _signIV = [[UIImageView alloc]initWithFrame:CGRectMake(20, 50, 60, 30)];
    _signIV.backgroundColor = [UIColor clearColor];
    _signIV.image = self.signImage;
    [self.view addSubview:_signIV];
    
    //添加手势
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [_signIV setUserInteractionEnabled:YES];//开启图片控件的用户交互
    [_signIV addGestureRecognizer:pan];//给图片添加手势
    
    
    
    NSString * file = [[NSBundle mainBundle]pathForResource:@"instance"ofType:@"pdf"];
    NSData * data  = [NSData dataWithContentsOfFile:file];
    [data writeToFile:pdfPath atomically:YES];
    
    //读取PDF原文件的大小
    NSURL *filePath = [NSURL fileURLWithPath:pdfPath];
    CGPDFDocumentRef doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)filePath);
    CGPDFPageRef page = CGPDFDocumentGetPage(doc, 1);
    CGRect mediaBox = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    NSLog(@"#mediaBox: %@",NSStringFromCGRect(mediaBox));
    
    self.PDFWidth  = [self floatWithdecimalNumber:mediaBox.size.width];
    self.PDFHeight = [self floatWithdecimalNumber:mediaBox.size.height];
}
- (float)floatWithdecimalNumber:(double)num {
    return [[self decimalNumber:num] doubleValue];
}
- (NSDecimalNumber *)decimalNumber:(double)num {
    NSString *numString = [NSString stringWithFormat:@"%.2f", num];
    return [NSDecimalNumber decimalNumberWithString:numString];
}

//签名
-(void)signName{
    //传入签名图片坐标  保存签名后的pdf路径。备注：这个(400, 145, 50, 20)坐标能签到准确位置
    //    NSString * savePath = @"/Users/fanqie/Desktop/instance.pdf";
    NSString * savePath = pdfPath;
    [SignaturePDF addSignature:_signImage onPDFFilePath:savePath drawRect:CGRectMake(350, 145,60 , 30)];
    [self.qLController reloadData];
    [_signIV removeFromSuperview];
}

//代理实现
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    //返回当前预览文件的个数
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    NSURL *filePath = [NSURL fileURLWithPath:pdfPath];
    //返回每一个要预览的文件的地址
    return  filePath;
}

#pragma mark - 手势执行的方法
-(void)handlePan:(UIPanGestureRecognizer *)rec{
    
    CGFloat KWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat KHeight = [UIScreen mainScreen].bounds.size.height;
    
    //返回在横坐标上、纵坐标上拖动了多少像素
    CGPoint point=[rec translationInView:self.view];
    NSLog(@"%f,%f",point.x,point.y);
    
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
