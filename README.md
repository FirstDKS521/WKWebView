#iOS开发：WKWebView的使用（设置cookie、不受信任的HTTPS、返回关闭按钮）

![效果GIF.gif](http://upload-images.jianshu.io/upload_images/1840399-844df8a77bd5d7b8.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

之前也是使用`UIWebView`，但是近期使用时碰到了问题，所以就想着更换成`WKWebView`。都知道`WKWebView`是在iOS8之后苹果推出的，也有很多大牛做了他和`UIWebView`的对比，此处小弟就在叙述了，可以参考[文章一](http://www.jianshu.com/p/4fa8c4eb1316)、[文章二](http://www.jianshu.com/p/403853b63537)，我也是取各家之所长，以及在使用过程中遇到的问题，写下这篇文章，仅供参考！

###创建`DKSWebController`继承自`UIViewController`，头文件如下：

```
#import <WebKit/WebKit.h>

@interface DKSWebController ()<WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;

//返回按钮
@property (nonatomic, strong) UIBarButtonItem *backItem;
//关闭按钮
@property (nonatomic, strong) UIBarButtonItem *closeItem;

//进度条
@property (nonatomic, strong) UIView *progressView;
@property (weak, nonatomic) CALayer *progresslayer;

@end
```

###具体实现如下：代码有点多，可以下载demo看看

```
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self addLeftButton]; //添加返回按钮
}

#pragma mark ====== 加载HTML ======
- (void)loadHtmlStr:(NSString *)htmlStr {
    NSURL *url = [NSURL URLWithString:htmlStr];
    
    //不需要cookie的话，此处只是简单打开H5页面
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark ====== 加载进度条 ======
- (void)addProgressView {
    //添加进度条（如果没有需要，可以注释掉）
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    UIView *progress = [[UIView alloc]initWithFrame:CGRectMake(0, navigationBarBounds.size.height, CGRectGetWidth(self.view.frame), 1)];
    progress.backgroundColor = [UIColor clearColor];
    [self.navigationController.navigationBar addSubview:progress];
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 0, 1);
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [progress.layer addSublayer:layer];
    self.progresslayer = layer;
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

//kvo 监听进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progresslayer.opacity = 1;
        self.progresslayer.frame = CGRectMake(0, 0, self.view.bounds.size.width * [change[NSKeyValueChangeNewKey] floatValue], 1);
        if ([change[NSKeyValueChangeNewKey] floatValue] == 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.opacity = 0;
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.frame = CGRectMake(0, 0, 0, 1);
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark ====== 添加进度条 ======
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addProgressView]; //添加进度条
}

#pragma mark ====== 移除进度条 ======
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //移除progressView，否则将会显示在其他的导航栏上面
    [self.progressView removeFromSuperview];
}

#pragma mark ====== WKWebViewDelegate ======
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    //设置webview的title
    self.title = webView.title;
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"网络不给力");
}

// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    //不允许跳转
    //decisionHandler(WKNavigationResponsePolicyCancel);
}

// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate
// 创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    return [[WKWebView alloc]init];
}

// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    completionHandler(@"http");
}

// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    completionHandler(YES);
}

// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

#pragma mark - 添加关闭按钮
- (void)addLeftButton {
    self.navigationItem.leftBarButtonItem = self.backItem;
}

//点击返回的方法
- (void)backNative {
    //判断是否有上一层H5页面
    if ([self.webView canGoBack]) {
        //如果有则返回
        [self.webView goBack];
        //同时设置返回按钮和关闭按钮为导航栏左边的按钮
        self.navigationItem.leftBarButtonItems = @[self.backItem, self.closeItem];
    } else {
        [self closeNative];
    }
}

//关闭H5页面，直接回到原生页面
- (void)closeNative {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ====== init ======
- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        [self.view addSubview:_webView];
    }
    return _webView;
}

- (UIBarButtonItem *)backItem {
    if (!_backItem) {
        _backItem = [[UIBarButtonItem alloc] init];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        //这是一张“<”的图片，可以让美工给切一张
        UIImage *image = [UIImage imageNamed:@"sy_back"];
        [btn setImage:image forState:UIControlStateNormal];
        [btn setTitle:@"返回" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(backNative) forControlEvents:UIControlEventTouchUpInside];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        //字体的多少为btn的大小
        [btn sizeToFit];
        //左对齐
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        //让返回按钮内容继续向左边偏移15，如果不设置的话，就会发现返回按钮离屏幕的左边的距离有点儿大，不美观
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
        btn.frame = CGRectMake(0, 0, 40, 40);
        _backItem.customView = btn;
    }
    return _backItem;
}

- (UIBarButtonItem *)closeItem {
    if (!_closeItem) {
        _closeItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeNative)];
        _closeItem.tintColor = [UIColor blackColor];
    }
    return _closeItem;
}

#pragma mark - 移除进度条的监听
- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end
```
以上就是WKWebView的使用方法；

###如果在使用时加载不受信任的HTTPS的话，需要实现代理方法如下：

```
//此方法在iOS8上面不执行，也就是iOS8目前不能加载不受信任的HTTPS（我目前知道的）
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}
```
但是此代理方法在iOS8上面并不执行，如果是自建证书，加载不受信任的HTTPS的话，此时在iOS8上面会显示白屏，到目前为止并没有找到解决方法。也有朋友提出解决方案，说使用正规的证书就行了，我的内心是抗拒的🤣。如果你有好的解决办法，一定要留言告知一声，万分感谢！

###加载H5时需要cookie，使用AJAX进行新的请求时需要cookie，也就是在跳转新的H5时也需要cookie的话，设置方法如下：

```
//在开始加载webview时就不能用上面的方法了
- (void)loadHtmlStr:(NSString *)htmlStr {
    NSURL *url = [NSURL URLWithString:htmlStr];
    //如果需要设置cookie验证的话，使用此段代码
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[self readCurrentCookieWithDomain] forHTTPHeaderField:@"Cookie"];
    [self.webView loadRequest:request];
}

#pragma mark ====== 设置cookie ======
- (NSString *)readCurrentCookieWithDomain {
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableString *cookieString = [[NSMutableString alloc] init];
    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
        [cookieString appendFormat:@"%@=%@;", cookie.name, cookie.value];
    }
    
    //删除最后一个“；”
    [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
    return cookieString;
}

// 在发送请求之前，决定是否跳转并设置cookie，带入到新的请求
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
     //此处是在页面跳转时，防止cookie丢失做的处理
    WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;
    NSURL *url = navigationAction.request.URL;
    //此处的m.duks.com是自己公司的域名
    if ([url.host isEqualToString:@"m.duks.com"]) {
        NSDictionary *headFields = navigationAction.request.allHTTPHeaderFields;
        NSString *cookie = headFields[@"Cookie"];
        if (cookie == nil) {
            //在跳转新的web页面时，把cookie传过去
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:navigationAction.request.URL];
            [request setValue:[self readCurrentCookieWithDomain] forHTTPHeaderField:@"Cookie"];
            [webView loadRequest:request];
            policy = WKNavigationActionPolicyCancel;
        }
    }
    
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}
```

###如果是比较老的项目使用WKWebView，并且使用过程中用到[WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge)，有可能会引起崩溃

```
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    //这一行崩溃
    decisionHandler(WKNavigationActionPolicyAllow);
}
```
此时我建议更新这个三方库，原因是这个方法被多次调用，这个库的作者也更新了这个问题；
