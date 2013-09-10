//
//  ViewController.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 4/30/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShaderManager.h"
#import "ShaderMenuViewController.h"

// Audio stuff
#import "AudioController.hpp"

@class ShaderViewController;

@interface GalleryViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, SWRevealViewControllerDelegate, ShaderManagerDelegate, ShaderMenuDelegate, AudioControllerDelegate>
{
    bool _revealControllerShowing;
    bool _loadingShaders;
    
    NSMutableArray* _viewControllers;
    NSMutableArray* _shaders;
    NSMutableArray* _pendingControllers;
    
    // Audio stuff
    AudioController *_audioManager;
}

@end
