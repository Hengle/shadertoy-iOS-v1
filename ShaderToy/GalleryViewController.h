//
//  ViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShaderManager.h"

@class ShaderViewController;

@interface GalleryViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, SWRevealViewControllerDelegate, ShaderManagerDelegate>
{
    bool _revealControllerShowing;
    bool _shadersReady;
    NSMutableArray *_viewControllers;
    NSMutableArray *_shaders;
    NSMutableArray* _pendingControllers;
}

@end
