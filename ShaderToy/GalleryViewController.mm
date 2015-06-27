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

#define MAX_CONTROLLERS 3

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
    
    // Others
    self.dataSource = self;
    self.delegate = self;
    
    self.revealViewController.delegate = self;
    
    MenuViewController* menuController = (MenuViewController *)self.revealViewController.rearViewController;
    menuController.delegate = self;
    
    _pendingControllers = [NSMutableArray new];
    _shaders = [NSMutableArray new];
    _shaderViewControllers = [NSMutableArray new];
    
    // Create the controllers
    for (int i = 0; i < MAX_CONTROLLERS; i++)
    {
        ShaderViewController* controller = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];
        [_shaderViewControllers addObject:controller];
    }
    
    // Initial section setup, we are good to go
    [self clearViewsForSectionChange];
    
    // Make a new shader request now that the views are set
    _shaderRequest = [ShaderRequest new];
    _shaderRequest.delegate = self;
    
    // Tap gesture recognizer to collapse reveal view controller
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ShaderViewController* firstController = (ShaderViewController *)_shaderViewControllers[0];
    [firstController startAnimation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    static dispatch_once_t initialRequest;
    dispatch_once(&initialRequest, ^{
        [_shaderRequest requestCategory:Newest];
    });
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    ShaderViewController* firstController = (ShaderViewController *)_shaderViewControllers[0];
    [firstController stopAnimation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)clearViewsForSectionChange
{
    [_shaders removeAllObjects];
 
    ShaderInfo* defaultShader = [ShaderManager sharedInstance].defaultShader;
    for (int i = 0; i < _shaderViewControllers.count; i++)
    {
        ShaderViewController* controller = (ShaderViewController *)_shaderViewControllers[i];
        [controller setShader:defaultShader];
    }
    
    ShaderViewController* firstController = (ShaderViewController *)_shaderViewControllers[0];
    [self setViewControllers:@[firstController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        [firstController startAnimation];
    }];
}

- (void)setUserInteractionState:(bool)enable
{
    if (enable)
    {
        if (disabledDataSource != nil)
        {
            self.dataSource = disabledDataSource;
            disabledDataSource = nil;
        }
    }
    else
    {
        if (disabledDataSource == nil)
        {
            disabledDataSource = self.dataSource;
            self.dataSource = nil;
        }
    }
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
    
    NSLog(@"[GalleryViewController] Pending controllers %lu", (unsigned long)_pendingControllers.count);
    NSLog(@"[GalleryViewController] Started Animation for next controller %@ with shader %@", next, next.currentShader.name);
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        ShaderViewController* previous = (ShaderViewController *)previousViewControllers[0];
        [previous stopAnimation];
        
        NSLog(@"[GalleryViewController] Stopped Animation for previews controller with shader %@.", previous.currentShader.name);
        
        ShaderViewController* current = (ShaderViewController *)pageViewController.viewControllers[0];
        
        if ([_pendingControllers containsObject:current])
        {
            [_pendingControllers removeObject:current];
        }
        
        // TODO: Pre-warm the controller, get the next shader in
        // the list and set the next free controller to use it
    }
    
    // If the animation didn't complete, our next view controllers are rendering
    // we need to stop its rendering as the animation failed
    for (ShaderViewController* controller in _pendingControllers)
    {
        [controller stopAnimation];
        NSLog(@"[GalleryViewController] Stopped Animation for pending controller with shader %@.", controller.currentShader.name);
    }
    
    [_pendingControllers removeAllObjects];
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ShaderViewController *)viewController
{
    ShaderViewController* previousController = nil;
    
    NSInteger shaderIndex = [_shaders indexOfObject:viewController.currentShader];
    if (shaderIndex != NSNotFound)
    {
        shaderIndex--;
        
        if (shaderIndex >= 0)
        {
            previousController = _shaderViewControllers[shaderIndex % _shaderViewControllers.count];
            
            ShaderInfo* shader = _shaders[shaderIndex];
            [previousController setShader:shader];
        
            NSLog(@"[GalleryViewController] Setting Before VC %d to shader %@", (int)(shaderIndex % _shaderViewControllers.count), shader.name);
        }
    }
    
    return previousController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ShaderViewController *)viewController
{
    ShaderViewController* nextController = nil;
    
    NSUInteger shaderIndex = [_shaders indexOfObject:viewController.currentShader];
    if (shaderIndex != NSNotFound)
    {
        shaderIndex++;
        
        if (shaderIndex < _shaders.count)
        {
            nextController = _shaderViewControllers[shaderIndex % _shaderViewControllers.count];
            
            ShaderInfo* shader = _shaders[shaderIndex];
            [nextController setShader:shader];
            
            NSLog(@"[GalleryViewController] Setting After VC %d to shader %@", (int)(shaderIndex % _shaderViewControllers.count), shader.name);
        }
    }
    
    return nextController;
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

    if (newCategory)
    {
        ShaderInfo* defaultShader = [ShaderManager sharedInstance].defaultShader;
        
        // If this is a new category request, just set the shaders to their appropriate shader
        for (int i = 0; i < _shaderViewControllers.count; i++)
        {
            ShaderViewController* controller = (ShaderViewController *)_shaderViewControllers[i];
            if (controller.currentShader == defaultShader)
            {
                [controller setShader:_shaders[i]];
            }
        }
    }
    
    // If we are retrieving more shaders for this category, make sure our datasource is reloaded so scrolling is smooth
    ShaderViewController* viewController = (ShaderViewController *)self.viewControllers[0];
    if (viewController != nil)
    {
        [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}


#pragma mark - MenuDelegate

- (void)shaderMenu:(MenuViewController *)shaderMenu choseShaderCategory:(EShaderCategory)category
{
    [self clearViewsForSectionChange];
    
    [_shaderRequest requestCategory:category];
}

@end
