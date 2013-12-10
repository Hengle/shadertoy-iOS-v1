//
//  ShaderInfoViewController.m
//  Shadertoy
//
//  Created by skumancer on 7/14/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderInfoViewController.h"
#import "ShaderInfo.h"
#import "ShaderViewController.h"

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
                       self.view.hidden = _shaderInfo.removeoverlay;
                       
                       _nameLabel.text = [_shaderInfo.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                       _authorLabel.text = [_shaderInfo.username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                       _descriptionLabel.text = [_shaderInfo.description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                       
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
    UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"Check out %@ by %@ in Shadertoy!", _shaderInfo.name, _shaderInfo.username], [NSString stringWithFormat:@"https://www.shadertoy.com/view/%@", _shaderInfo.ID]] applicationActivities:nil];
    
    
    [_shaderViewController presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)like:(id)sender
{
}

@end
