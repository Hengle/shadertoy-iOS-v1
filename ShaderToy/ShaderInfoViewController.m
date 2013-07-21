//
//  ShaderInfoViewController.m
//  Shadertoy
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setShaderInfo:(ShaderInfo *)info
{
    _shaderInfo = info;
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _nameLabel.text = _shaderInfo.name;
                       _authorLabel.text = _shaderInfo.username;
                       _descriptionLabel.text = _shaderInfo.description;
                       
                       NSMutableString* tags = [NSMutableString new];
                       for (int i = 0; i < _shaderInfo.tags.count; i++)
                       {
                           if (i < _shaderInfo.tags.count - 1)
                           {
                               [tags appendFormat:@"%@, ", _shaderInfo.tags[i]];
                           }
                           else
                           {
                               [tags appendString:_shaderInfo.tags[i]];
                           }
                       }
                       
                       _tagsLabel.text = tags;
                       
                       [_likeButton setTitle:[NSString stringWithFormat:@"%d", _shaderInfo.likes] forState:UIControlStateNormal];
                       [_viewsButton setTitle:[NSString stringWithFormat:@"%d", _shaderInfo.viewed] forState:UIControlStateNormal];
                   });
}

- (IBAction)share:(id)sender
{
//    UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[@"Check out this shader in Shadertoy!", [NSString stringWithFormat:@"http://www.shadertoy.com/view/%@", _shaderInfo.ID]] applicationActivities:nil];
//    
//    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)like:(id)sender
{
}

@end
