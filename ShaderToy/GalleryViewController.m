//
//  ViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "GalleryViewController.h"
#import "ShaderViewController.h"
#import "ShaderManager.h"

@interface GalleryViewController ()

@end

@implementation GalleryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.dataSource = self;
    self.delegate = self;
    
    self.revealViewController.delegate = self;
    
    // Retrieve the shaders we have available and filter the list to only include name.extension
    shaders = [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh" inDirectory:nil];
    
    NSMutableArray* filteredlist = [NSMutableArray new];
    for (NSString* path in shaders)
    {
        [filteredlist addObject:path.lastPathComponent];
    }
    
    shaders = filteredlist;
    
    viewControllers = [NSMutableArray new];
    
    for (int i = 0; i < 3; i++)
    {
        ShaderViewController* viewController = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];
        
        NSString* shaderName = shaders[i];
        [viewController setShader:shaderName];
        
        [viewControllers addObject:viewController];
    }
    
    // Set the first page controller
    ShaderViewController* firstController = viewControllers[0];
    [self setViewControllers:@[firstController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    // Start the animation
    [firstController startAnimation];
    
    // Pre-compile shaders
    ShaderManager* shaderManager = [ShaderManager sharedInstance];
    for (NSString* name in shaders)
    {
        [shaderManager addShader:name];
    }
    
    // Tap gesture recognizer to collapse reveal view controller
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    ShaderViewController* next = (ShaderViewController *)pendingViewControllers[0];
    [next startAnimation];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        ShaderViewController* previous = (ShaderViewController *)previousViewControllers[0];
        [previous stopAnimation];
    }
}


#pragma mark -
#pragma UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    int shaderIndex = [shaders indexOfObject:viewController.currentShader] - 1;
    
    if (shaderIndex >= 0)
    {
        newController = viewControllers[shaderIndex % 3];
        NSString* shaderName = shaders[shaderIndex];
        [newController setShader:shaderName];
    }
    
    return newController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    int shaderIndex = [shaders indexOfObject:viewController.currentShader] + 1;
    
    if (shaderIndex < shaders.count)
    {
        newController = viewControllers[shaderIndex % 3];
        
        if (newController.sharegroup == nil)
        {
            newController.sharegroup = viewController.sharegroup;
        }
        
        NSString* shaderName = shaders[shaderIndex];
        [newController setShader:shaderName];
    }
    
    return newController;
}


#pragma mark -
#pragma mark UITapGestureRecognizer

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // Only allow tap to reveal when the menu is revealed
        if (revealControllerShowing)
        {
            [self.revealViewController revealToggleAnimated:YES];
        }
    }
}

#pragma mark -
#pragma mark SWRevealViewController

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    revealControllerShowing = (position == FrontViewPositionRight);
}

@end
