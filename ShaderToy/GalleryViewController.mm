//
//  ViewController.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "GalleryViewController.hpp"
#import "ShaderViewController.h"
#import "ShaderInfo.h"
#import "ShaderManager.h"

#define MAX_CONTROLLERS 4

@interface GalleryViewController ()
{
    ShaderRequest* _shaderRequest;
}
- (void)clearViewsForSectionChange;

@end

@implementation GalleryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Audio
    _audioManager = [AudioController sharedAudioManager];
    _audioManager.delegate = self;
    
    // Others
    self.dataSource = self;
    self.delegate = self;
    
    self.revealViewController.delegate = self;
    
    ShaderMenuViewController* menuController = (ShaderMenuViewController *)self.revealViewController.rearViewController;
    menuController.delegate = self;
    
    _pendingControllers = [NSMutableArray new];
    _shaders = [NSMutableArray new];
    _viewControllers = [NSMutableArray new];
    
    // Create the first controller and start the animation
    ShaderViewController* viewController = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];
    ShaderInfo* shader = [ShaderManager sharedInstance].defaultShader;
    [viewController setShader:shader];
    [_viewControllers addObject:viewController];
    
    [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [viewController startAnimation];
    
    _shaderRequest = [ShaderRequest new];
    _shaderRequest.delegate = self;
    
    [_shaderRequest requestCategory:Newest];
    
    // Tap gesture recognizer to collapse reveal view controller
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)clearViewsForSectionChange
{
    [_shaders removeAllObjects];
 
    ShaderInfo* shader = [ShaderManager sharedInstance].defaultShader;
    ShaderViewController* viewController = (ShaderViewController *)self.viewControllers[0];
    [viewController setShader:shader];
    [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:
     ^(BOOL finished)
     {
         [viewController startAnimation];
     }];
}


#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    ShaderViewController* next = (ShaderViewController *)pendingViewControllers[0];
    [next startAnimation];
    
    if (![_pendingControllers containsObject:next])
    {
        [_pendingControllers addObject:next];
    }
    
    // If this is the last shader we have, put a request in for more shaders
    NSUInteger shaderIndex = [_shaders indexOfObject:next.currentShader];
    if (shaderIndex >= (_shaders.count - 1))
    {
        [_shaderRequest requestNewShaders];
    }
    
    NSLog(@"Pending controller %u", _pendingControllers.count);
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


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    
    NSInteger shaderIndex = [_shaders indexOfObject:viewController.currentShader];
    if (shaderIndex != NSNotFound)
    {
        shaderIndex--;
        
        if (shaderIndex >= 0)
        {
            newController = _viewControllers[shaderIndex % _viewControllers.count];
            ShaderInfo* shader = _shaders[shaderIndex];
            [newController setShader:shader];
        
            NSLog(@"Setting VC %u to shader %@", shaderIndex % _viewControllers.count, shader.name);
        }
    }
    
    return newController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    
    NSUInteger shaderIndex = [_shaders indexOfObject:viewController.currentShader];
    if (shaderIndex != NSNotFound)
    {
        shaderIndex++;
        
        if (shaderIndex < _shaders.count)
        {
            newController = _viewControllers[shaderIndex % _viewControllers.count];
            
            ShaderInfo* shader = _shaders[shaderIndex];
            [newController setShader:shader];
            
            NSLog(@"Setting VC %u to shader %@", (shaderIndex % _viewControllers.count), shader.name);
        }
    }
    
    return newController;
}


#pragma mark - UITapGestureRecognizer

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


#pragma mark - SWRevealViewController

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    _revealControllerShowing = (position == FrontViewPositionRight);
}


#pragma mark - ShaderRequestDelegate

- (void)shaderRequest:(ShaderRequest *)request hasShadersReady:(NSArray *)shaderList
{
    bool newCategory = (_shaders.count <= 0);
    [_shaders addObjectsFromArray:shaderList];
    
    ShaderInfo* defaultShader = [ShaderManager sharedInstance].defaultShader;
    
    if (_viewControllers.count < MAX_CONTROLLERS)
    {
        ShaderViewController* viewController = (ShaderViewController *)self.viewControllers[0];
        if (viewController.currentShader == defaultShader)
        {
            [viewController setShader:_shaders[0]];
        }
        
        // Create the controllers
        for (int i = 1; i < MAX_CONTROLLERS; i++)
        {
            ShaderViewController* controller = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];
            [controller setShader:_shaders[i]];
            
            [_viewControllers addObject:controller];
        }
    }
    else if (newCategory)
    {
        for (int i = 0; i < _viewControllers.count; i++)
        {
            ShaderViewController* controller = (ShaderViewController *)_viewControllers[i];
            if (controller.currentShader == defaultShader)
            {
                [controller setShader:_shaders[i]];
            }
        }
    }
}


#pragma mark - ShaderMenuDelegate

- (void)shaderMenu:(ShaderMenuViewController *)shaderMenu choseShaderCategory:(EShaderCategory)category
{
    [self clearViewsForSectionChange];
    
    [_shaderRequest requestCategory:category];
}

#pragma mark - Audio stuff

- (void) receivedWaveSamples:(SInt32 *)samples length:(int)len
{
    int average = 0;
    for(int i = 0 ; i < len ; i ++)
    {
        average += samples[i];
    }
    //NSLog(@"Wave %d", average / len);
}

- (void) receivedFreqSamples:(int32_t*) samples length:(int) len;
{
    int average = 0;
    for(int i = 0 ; i < len ; i ++)
    {
        average += samples[i];
    }
    //NSLog(@"FFT %d", average / len);
}

@end
