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
    
    _pendingControllers = [NSMutableArray new];
    
    // Retrieve the shaders we have available and filter the list to only include name.extension
    _shaders = [[NSBundle mainBundle] pathsForResourcesOfType:@"fsh" inDirectory:nil];
    
    NSMutableArray* filteredlist = [NSMutableArray new];
    for (NSString* path in _shaders)
    {
        [filteredlist addObject:path.lastPathComponent];
    }
    
    _shaders = filteredlist;
    
    _viewControllers = [NSMutableArray new];
    
    for (int i = 0; i < 4; i++)
    {
        ShaderViewController* viewController = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];

        NSString* shaderName = _shaders[i];
        [viewController setShader:shaderName];
 
        [_viewControllers addObject:viewController];
    }
    
    // Set the first page controller
    ShaderViewController* firstController = _viewControllers[0];
    [self setViewControllers:@[firstController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    // Start the animation
    [firstController startAnimation];
    
    // Pre-compile shaders
    ShaderManager* shaderManager = [ShaderManager sharedInstance];
    for (NSString* name in _shaders)
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
    
    if (![_pendingControllers containsObject:next])
    {
        [_pendingControllers addObject:next];
    }
    
    NSLog(@"Pending controller %d", _pendingControllers.count);
    NSLog(@"Started Animation for next controller %@", next);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        ShaderViewController* previous = (ShaderViewController *)previousViewControllers[0];
        [previous stopAnimation];
        
        for (ShaderViewController* controller in _pendingControllers)
        {
            if (controller != pageViewController.viewControllers[0])
            {
                [controller stopAnimation];
                
                NSLog(@"Stopped Animation for previews controller");
            }
        }
        
        // Pre-warm the controller, get the next shader in
        // the list and set the next free controller to use it
    }
    else
    {
        // If the animation didn't complete, our next view controllers are rendering
        // we need to stop its rendering as the animation failed
        for (ShaderViewController* controller in _pendingControllers)
        {
            [controller stopAnimation];
            NSLog(@"Stopped Animation for pending controller");
        }
    }

    [_pendingControllers removeAllObjects];
}


#pragma mark -
#pragma UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    int shaderIndex = [_shaders indexOfObject:viewController.currentShader] - 1;
    
    if (shaderIndex >= 0)
    {
        newController = _viewControllers[shaderIndex % _viewControllers.count];
        NSString* shaderName = _shaders[shaderIndex];
        [newController setShader:shaderName];
        
        NSLog(@"Setting VC %d to shader %@", shaderIndex % _viewControllers.count, shaderName);
    }
    
    return newController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    int shaderIndex = [_shaders indexOfObject:viewController.currentShader] + 1;
    
    if (shaderIndex < _shaders.count)
    {
        newController = _viewControllers[shaderIndex % _viewControllers.count];
        
        if (newController.sharegroup == nil)
        {
            newController.sharegroup = viewController.sharegroup;
        }
        
        NSString* shaderName = _shaders[shaderIndex];
        [newController setShader:shaderName];
        
        NSLog(@"Setting VC %d to shader %@", shaderIndex % _viewControllers.count, shaderName);
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
        if (_revealControllerShowing)
        {
            [self.revealViewController revealToggleAnimated:YES];
        }
    }
}

#pragma mark -
#pragma mark SWRevealViewController

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    _revealControllerShowing = (position == FrontViewPositionRight);
}

@end
