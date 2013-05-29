//
//  ViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, SWRevealViewControllerDelegate>
{
    bool revealControllerShowing;
    NSMutableArray *viewControllers;
    NSArray *shaders;
}

@end
