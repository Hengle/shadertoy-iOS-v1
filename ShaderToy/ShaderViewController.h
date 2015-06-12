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
    bool _oneFrame;
    bool _running;
    bool _animating;
    bool _initialized;
    bool _overlayVisible;
    bool _firstFrame;
    unsigned long _frameDropCounter;
    unsigned long _frameCounter;
    
    float firstX, firstY;
    
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
}

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *viewsButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (strong, nonatomic) IBOutlet ShaderView* shaderView;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, readonly) ShaderInfo* currentShader;


- (IBAction)toggleMenu:(id)sender;
- (IBAction)toggleOverlay:(id)sender;
- (IBAction)flashOverlay:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)like:(id)sender;

- (void)drawPreviewFrame;
- (void)startAnimation;
- (void)stopAnimation;
- (void)setShader:(ShaderInfo *)shader;
- (void)setOverlayVisible:(BOOL)visible;

@end
