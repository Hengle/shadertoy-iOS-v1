//
//  ViewController.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ShaderRequest.h"
#import "MenuViewController.h"

@class ShaderViewController;

@interface GalleryViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, SWRevealViewControllerDelegate, ShaderRequestDelegate, MenuDelegate>
{
    bool _revealControllerShowing;
    bool _loadingShaders;
    
    NSMutableArray* _shaderViewControllers;
    NSMutableArray* _shaders;
    NSMutableArray* _pendingControllers;
}

@end
