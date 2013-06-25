//
//  ViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "GalleryViewController.h"
#import "ShaderViewController.h"
#import "ShaderInfo.h"

@interface GalleryViewController ()

@end

@implementation GalleryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = self;
    self.delegate = self;
    
    self.revealViewController.delegate = self;
    
    [ShaderManager sharedInstance].delegate = self;
    
    _shadersReady = false;
    _pendingControllers = [NSMutableArray new];
    _shaders = [NSMutableArray new];
    _viewControllers = [NSMutableArray new];
    
    ShaderViewController* viewController = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];
    ShaderInfo* shader = [ShaderManager sharedInstance].defaultShader;
    [viewController setShader:shader];
    [_viewControllers addObject:viewController];
    
    [self setViewControllers:@[viewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    [viewController startAnimation];
    
    // Background loading of shaders
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       NSData* shaderListData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://www.shadertoy.com/mobile.htm?sort=newest"]];
                       
                       if (shaderListData != nil)
                       {
                           NSError* listError = nil;
                           NSArray* shaderList = [NSJSONSerialization JSONObjectWithData:shaderListData options:kNilOptions error:&listError];
                           
                           if (listError == nil)
                           {
                               for (NSString* shaderID in shaderList)
                               {
                                   NSData* shaderDetailsData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.shadertoy.com/mobile.htm?s=%@", shaderID]]];
                                   
                                   NSError* detailError = nil;
                                   NSArray* shaderDetails = [NSJSONSerialization JSONObjectWithData:shaderDetailsData options:kNilOptions error:&detailError];
                                   
                                   if (detailError == nil)
                                   {
                                       ShaderInfo* shader = [[ShaderInfo alloc] initWithJSONDictionary:shaderDetails[0]];
                                       
                                       [_shaders addObject:shader];
                                       [[ShaderManager sharedInstance] addShader:shader];
                                   }
                                   else
                                   {
                                       NSLog(@"Error loading shader details %@", detailError.localizedDescription);
                                   }
                               }
                           }
                           else
                           {
                               NSLog(@"Error loading shader list %@", listError.localizedDescription);
                           }
                       }
                   });
    
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


#pragma mark - UIPageViewControllerDelegate

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


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    
    if (_shadersReady)
    {
        int shaderIndex = [_shaders indexOfObject:viewController.currentShader];
        
        if (shaderIndex != NSNotFound)
        {
            shaderIndex -= 1;
            if (shaderIndex >= 0)
            {
                newController = _viewControllers[shaderIndex % _viewControllers.count];
                ShaderInfo* shader = _shaders[shaderIndex];
                [newController setShader:shader];
                
                NSLog(@"Setting VC %d to shader %@", shaderIndex % _viewControllers.count, shader.name);
            }
        }
    }
    
    return newController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ShaderViewController *)viewController
{
    ShaderViewController* newController = nil;
    
    if (_shadersReady)
    {
        int shaderIndex = [_shaders indexOfObject:viewController.currentShader];
        
        if (shaderIndex != NSNotFound)
        {
            shaderIndex += 1;
            if (shaderIndex < _shaders.count)
            {
                newController = _viewControllers[shaderIndex % _viewControllers.count];
                
                if (newController.sharegroup == nil)
                {
                    newController.sharegroup = viewController.sharegroup;
                }
                
                ShaderInfo* shader = _shaders[shaderIndex];
                [newController setShader:shader];
                
                NSLog(@"Setting VC %d to shader %@", shaderIndex % _viewControllers.count, shader.name);
            }
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


#pragma mark - ShaderManagerDelegate

- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager
{
    for (int i = 0; i < 3; i++)
    {
        ShaderViewController* viewController = (ShaderViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ShaderView"];

        ShaderInfo* shader = [ShaderManager sharedInstance].defaultShader;
        [viewController setShader:shader];

        [_viewControllers addObject:viewController];
    }
    
    ShaderViewController* viewController = (ShaderViewController *)self.viewControllers[0];
    [viewController setShader:_shaders[0]];
    
    _shadersReady = true;

    // Set the first page controller
    //ShaderViewController* firstController = _viewControllers[0];
    //[self setViewControllers:@[firstController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    // Start the animation
    //[firstController startAnimation];
}

@end
