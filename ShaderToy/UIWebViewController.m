//
//  UIWebViewController.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 12/3/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "UIWebViewController.h"

@interface UIWebViewController ()
{
    UIButton* _closeButton;
}

@end

@implementation UIWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 30.0f, 30.0f)];
    _closeButton.accessibilityLabel = @"close";
    [_closeButton setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.shadertoy.com/aboutios"]];
    [self.webView loadRequest:request];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

// Support for earlier than iOS 6.0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark - Actions

- (IBAction)closeView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isShadertoyLink = [request.URL.host isEqualToString:@"www.shadertoy.com"];
    if (navigationType == UIWebViewNavigationTypeLinkClicked && !isShadertoyLink)
    {
        [[UIApplication sharedApplication] openURL:request.URL];
    }
    
    return isShadertoyLink;
}

@end
