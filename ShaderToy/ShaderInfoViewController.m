//
//  ShaderInfoViewController.m
//  ShaderToy
//
//  Created by skumancer on 7/14/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderInfoViewController.h"
#import "ShaderInfo.h"

#import <QuartzCore/QuartzCore.h>

@interface ShaderInfoViewController ()

@end

@implementation ShaderInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //self.title = NSLocalizedString(@"Blur", nil);
    //self.navigationItem.title = self.title;
    //self.navigationController.navigationBar.translucent = YES;
    
    //DKLiveBlurView *backgroundView = [[DKLiveBlurView alloc] initWithFrame: self.view.bounds];
    
    //backgroundView.originalImage = [UIImage imageNamed:@"bg1.jpg"];
    //backgroundView.scrollView = self.tableView;
    //backgroundView.isGlassEffectOn = YES;
    
    //self.tableView.backgroundView = backgroundView;
    //self.tableView.contentInset = UIEdgeInsetsMake(kDKTableViewDefaultContentInset, 0, 0, 0);
    //self.scrollView.contentOffset = CGPointMake(0.0f, -300.0f);
    //self.scrollView.contentInset = UIEdgeInsetsMake(100.0f, 0.0f, 0.0f, 0.0f);
    [self.scrollView setContentOffset:CGPointMake(0.0f, self.scrollView.contentSize.height - self.scrollView.bounds.size.height)];
    
    //[self.view addSubview: self.tableView];
    
    CALayer* layer = self.scrollView.layer;
    
    layer.rasterizationScale = 0.25f;
    layer.shouldRasterize = TRUE;
}

//- (void)viewWillLayoutSubviews
//{
//    NSLog(@"viewWillLayoutSubviews");
//    
//}
//
//- (void)viewDidLayoutSubviews
//{
//    NSLog(@"viewDidLayoutSubviews");
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setShaderInfo:(ShaderInfo *)shaderInfo
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _nameLabel.text = shaderInfo.name;
                       _authorLabel.text = shaderInfo.username;
                       _descriptionLabel.text = shaderInfo.description;
                       
                       NSMutableString* tags = [NSMutableString new];
                       for (int i = 0; i < shaderInfo.tags.count; i++)
                       {
                           if (i < shaderInfo.tags.count - 1)
                           {
                               [tags appendFormat:@"%@, ", shaderInfo.tags[i]];
                           }
                           else
                           {
                               [tags appendString:shaderInfo.tags[i]];
                           }
                       }
                       
                       _tagsLabel.text = tags;
                       
                       [_likeButton setTitle:[NSString stringWithFormat:@"%d", shaderInfo.likes] forState:UIControlStateNormal];
                   });
}

- (IBAction)share:(id)sender
{
}

- (IBAction)like:(id)sender
{
}

@end
