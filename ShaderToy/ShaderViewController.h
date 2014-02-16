//
//  ParallaxViewController.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class Plane;
@class ShaderView;
@class ShaderInfo;
@class ShaderParameters;

@interface ShaderViewController : UIViewController
{
    bool _running;
    bool _animating;
    bool _initialized;
    unsigned long _frameDropCounter;
    unsigned long _frameCounter;
    
    Plane* _planeObject;
    ShaderParameters* _params;
    
    NSDate* _startTime;
    NSDate* _lastFrameTime;
    NSDate* _lastFPSTime;
    
    // Multithreading support
    NSThread* _renderThread;
    NSRunLoop* _renderLoop;
    dispatch_queue_t _renderQueue;
    
    UITouch* _touchLocation;
    
    float firstX, firstY;
}

@property (strong, nonatomic) ShaderView* view;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, readonly) ShaderInfo* currentShader;

- (IBAction)toggleMenu:(id)sender;

- (void)startAnimation;
- (void)stopAnimation;
- (void)setShader:(ShaderInfo *)shader;

@end
