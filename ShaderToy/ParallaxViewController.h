//
//  ParallaxViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class Plane;

@class ShaderInformationViewController;

@interface ParallaxViewController : UIViewController <GLKViewDelegate>
{
    float contentScale;
    
    NSDate* startTime;
    
    Plane* planeObject;
    
    // Rendering loop
    CADisplayLink* displayLink;
    
    // Multithreading support
    dispatch_semaphore_t frameRenderingSemaphore;
    dispatch_queue_t openGLESContextQueue;
    
    CGPoint lastTouch;
}

@property (strong, nonatomic) ShaderInformationViewController *informationViewController;
@property (strong, nonatomic) GLKView* view;
@property (strong, nonatomic) IBOutlet UIButton *menuButton;
@property (assign) int index;

- (IBAction)toggleMenu:(id)sender;

@end
