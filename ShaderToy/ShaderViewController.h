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
@class ShaderView;
@class ShaderInformationViewController;
@class ShaderInfo;

@interface ShaderViewController : UIViewController
{
    bool _running;
    bool _animating;
    bool _initialized;
    unsigned long _frameDropCounter;
    
    Plane* _planeObject;
    
    NSDate* _startTime;
    
    // Multithreading support
    NSThread* _renderThread;
    NSRunLoop* _renderLoop;
    dispatch_queue_t _renderQueue;
    
    UITouch* _touchLocation;
}

@property (strong, nonatomic) ShaderInformationViewController *informationViewController;
@property (strong, nonatomic) ShaderView* view;
@property (strong, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) EAGLSharegroup *sharegroup;
@property (strong, readonly) ShaderInfo* currentShader;

- (IBAction)toggleMenu:(id)sender;

- (void)startAnimation;
- (void)stopAnimation;
- (void)setShader:(ShaderInfo *)shader;

@end
