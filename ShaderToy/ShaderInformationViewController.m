//
//  ShaderInformationViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/13/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderInformationViewController.h"
#import "ShaderInformation.h"

#import <Social/Social.h>

@interface ShaderInformationViewController ()

@end

@implementation ShaderInformationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Get the size of 
    float yPosition = self.view.frame.size.height - 120;
    self.view.frame = CGRectMake(0, yPosition, self.view.frame.size.width, self.view.frame.size.height);
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tap.numberOfTapsRequired = 1;
    
    [self.view addGestureRecognizer:tap];
}

- (void)dealloc
{
    NSLog(@"Going out of style!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)share:(id)sender
{
    NSString* shareBody = [NSString stringWithFormat:@"Check out this awesome shader: %@ by %@ on ShaderToy! http://www.shadertoy.com/", self.shaderInformation.shaderName, self.shaderInformation.authorName];
    
    UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[shareBody] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)like:(id)sender
{
    // TODO: add API call
}

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self.view];
    
    if (tapPoint.y < 120)
    {
        CGRect frame = self.view.frame;
        float yPosition = ((frame.origin.y <= 0) ? (frame.size.height - 120) : 0);
        
        CGRect newFrame = CGRectMake(0, yPosition, frame.size.width, frame.size.height);
        
        [UIView beginAnimations:@"translation" context:nil];
        [UIView setAnimationDuration:0.5f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        
        self.view.frame = newFrame;
        
        [UIView commitAnimations];
    }
}

@end
