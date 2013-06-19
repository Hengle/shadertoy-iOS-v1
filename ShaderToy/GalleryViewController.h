//
//  ViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShaderViewController;

@interface GalleryViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, SWRevealViewControllerDelegate>
{
    bool _revealControllerShowing;
    NSMutableArray *_viewControllers;
    NSArray *_shaders;
    NSMutableArray* _pendingControllers;
}

@end
