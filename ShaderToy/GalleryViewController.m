//
//  ViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "GalleryViewController.h"
#import "ParallaxViewController.h"

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
    
    colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
    viewControllers = [NSMutableArray new];
    
    for (int i = 0; i < colors.count; i++)
    {
        ParallaxViewController* viewController = [[ParallaxViewController alloc] initWithNibName:@"ParallaxViewController" bundle:nil];
        viewController.view.backgroundColor = colors[i];
        viewController.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Shader_%d", (i + 1)]];
        
        [viewControllers addObject:viewController];
    }
    
    [self setViewControllers:@[viewControllers[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    [self.revealButton setTarget:self.revealViewController];
    [self.revealButton setAction:@selector(revealToggle:)];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
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
    
}


#pragma mark -
#pragma UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    int index = [viewControllers indexOfObject:viewController];
    int newIndex = index - 1;
    
    return (newIndex >= 0 ? viewControllers[newIndex] : nil);
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    int index = [viewControllers indexOfObject:viewController];
    int newIndex = index + 1;
    
    return (newIndex < viewControllers.count ? viewControllers[newIndex] : nil);
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
