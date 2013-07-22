//
//  ParallaxViewController.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderViewController.h"
#import "ShaderManager.h"
#import "ShaderInfo.h"
#import "ShaderView.h"
#import "Plane.h"
#import "ChannelResourceManager.h"
#import "ShaderInfoViewController.h"

#import "SWRevealViewController.h"

#import <QuartzCore/QuartzCore.h>


#define OverlayMinAlpha 0.2f
#define OverlayMaxAlpha 0.5f
#define OverlayAnimationSpeed 0.35f

@interface ShaderViewController ()
{
    ShaderInfoViewController* _infoViewController;
    UIButton* _menuButton;
}

- (void)tearDown;
- (void)initialize;
- (void)drawFrame;
- (void)checkForErrors;
- (void)triggerDrawFrame;
- (void)threadMainLoop;

@end

@implementation ShaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([ShaderManager sharedInstance].defaultSharegroup == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [ShaderManager sharedInstance].defaultSharegroup = _context.sharegroup;
    }
    else
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:[ShaderManager sharedInstance].defaultSharegroup];
    }
    
    if (!_context)
    {
        NSLog(@"Failed to create ES context");
        exit(0);
    }
    
    self.view.contentScaleFactor = 1.0f;
    
    _renderThread = nil;
    _animating = false;
    _running = false;
    _initialized = false;
    _frameDropCounter = 0;
    _lastFrameTime = [NSDate date];
    _renderQueue = dispatch_queue_create("com.shadertoy.threadedgcdqueue", NULL);
    
    _infoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ShaderInfoOverlay"];
    _infoViewController.shaderViewController = self;
    _infoViewController.view.frame = CGRectMake(0, self.view.frame.size.height - _infoViewController.view.frame.size.height, self.view.frame.size.width, _infoViewController.view.frame.size.height);
    _infoViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_infoViewController.view addGestureRecognizer:panGesture];
    
    [self.view addSubview:_infoViewController.view];
    
    // Reset the overlay position
    _infoViewController.view.center = CGPointMake(_infoViewController.view.center.x, self.view.frame.size.height);
    _infoViewController.view.backgroundColor = [_infoViewController.view.backgroundColor colorWithAlphaComponent:OverlayMinAlpha];
    
    _menuButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 30.0f, 30.0f)];
    [_menuButton setImage:[UIImage imageNamed:@"menu.png"] forState:UIControlStateNormal];
    [_menuButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_menuButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Set the shader information to the overlay
    _infoViewController.shaderInfo = self.currentShader;
    
    // Reset the overlay position
    _infoViewController.view.center = CGPointMake(_infoViewController.view.center.x, self.view.frame.size.height);
    _infoViewController.view.backgroundColor = [_infoViewController.view.backgroundColor colorWithAlphaComponent:OverlayMinAlpha];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Reset the overlay position
    _infoViewController.view.center = CGPointMake(_infoViewController.view.center.x, self.view.frame.size.height);
    _infoViewController.view.backgroundColor = [_infoViewController.view.backgroundColor colorWithAlphaComponent:OverlayMinAlpha];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Reset the overlay position
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    _infoViewController.view.center = CGPointMake(_infoViewController.view.center.x, self.view.frame.size.height);
    _infoViewController.view.backgroundColor = [_infoViewController.view.backgroundColor colorWithAlphaComponent:OverlayMinAlpha];
    [UIView commitAnimations];
}

- (void)dealloc
{
    [self tearDown];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self tearDown];
    }
    
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

// Support for earlier than iOS 6.0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)startAnimation
{
    _startTime = [NSDate date];
    
    if (!_animating)
    {
        _animating = true;
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop) object:nil];
        
        [_renderThread start];
    }
}

- (void)stopAnimation
{
    if (_animating)
    {
        _animating = false;
        
        CFRunLoopStop([_renderLoop getCFRunLoop]);
        
        // Wait for the thread to finish
        @synchronized(_renderThread)
        {
            _renderThread = nil;
        }
    }
}

- (void)setShader:(ShaderInfo *)shader
{
    _currentShader = shader;
    
    // Set the shader information to the overlay
    _infoViewController.shaderInfo = self.currentShader;
    
    // For bookkeeping purposes
    _renderThread.name = self.currentShader.name;
    
    if (_planeObject)
    {
        [_planeObject useShader:_currentShader];
        
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            [_params clearChannels];
            
            // Inputs are only set only on initialization, no need to re-set them
            for (ShaderInput* input in renderpass.inputs)
            {
                if ([input.type isEqual: @"texture"])
                {
                    NSData* imageData = [[ChannelResourceManager sharedInstance] getResourceWithName:input.source];
                    
                    if (imageData != nil)
                    {
                        NSError* error = nil;
                        GLKTextureInfo* info = [GLKTextureLoader textureWithContentsOfData:imageData options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
                        
                        if (error == nil)
                        {
                            _params.channelInfo[input.channel] = info.name;
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"Setting shader to %@", shader.name);
}

- (void)tearDown
{
    [self stopAnimation];
    
    @synchronized(_context)
    {
        if (_context)
        {
            if (_context == [EAGLContext currentContext])
            {
                _planeObject = nil;
                [EAGLContext setCurrentContext:nil];
            }
            
            _context = nil;
        }
    }
}

- (void)initialize
{
    if (!_initialized)
    {
        self.view.context = _context;
        _initialized = true;
        _planeObject = [[Plane alloc] initWithShader:_currentShader];
        
        // Create a params object for this shader
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            _params = [[ShaderParameters alloc] init];
            
            // Inputs are only set only on initialization, no need to re-set them
            for (ShaderInput* input in renderpass.inputs)
            {
                if ([input.type isEqual: @"texture"])
                {
                    NSData* imageData = [[ChannelResourceManager sharedInstance] getResourceWithName:input.source];
                    
                    if (imageData != nil)
                    {
                        NSError* error = nil;
                        GLKTextureInfo* info = [GLKTextureLoader textureWithContentsOfData:imageData options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
                        
                        if (error == nil)
                        {
                            _params.channelInfo[input.channel] = info.name;
                            
                            NSLog(@"Setting input channel %d to texture %d", input.channel, _params.channelInfo[input.channel]);
                        }
                    }
                }
            }
        }
    }
}

- (void)drawFrame
{
    @synchronized(_context)
    {
        glPushGroupMarkerEXT(0, "Drawing");
        
        [self.view setFramebuffer];
        
        // Calculate the width and height of the view
        float width = self.view.backingWidth;
        float height = self.view.backingHeight;
        
        // Calculate the time since since rendering start
        float time = [[NSDate date] timeIntervalSinceDate:_startTime];
        
        // Clear the context
        glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glViewport(0, 0, width, height);
        
        // Iterate over renderpasses and send the appropriate values to the shader
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            // Setup the parameters that are sent to the shader
            _params.resolution = GLKVector3Make(width, height, 1.0f);
            _params.time = time;
            
            // Send touch locations, if valid, otherwise send 0
            if (_touchLocation != nil)
            {
                CGPoint point = [_touchLocation locationInView:self.view];
                _params.mouseCoordinates = GLKVector4Make(point.x, self.view.bounds.size.height - point.y, 1.0f, 1.0f);
            }
            else
            {
                _params.mouseCoordinates = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
            }
            
            // Draw the plane
            [_planeObject draw:_params];
        }
        
        [self.view presentFramebuffer];
        
        glPopGroupMarkerEXT();
    }
}

- (void)update
{
    float time = [[NSDate date] timeIntervalSinceDate:_lastFrameTime];
    
    [[ShaderManager sharedInstance] deferCompilation];
    [[ChannelResourceManager sharedInstance] deferLoading];
    
    [_planeObject update:time];
    
    _lastFrameTime = [NSDate date];
}

- (void)checkForErrors
{
#if DEBUG
    GLenum error = glGetError();
    if (error > 0x0)
    {
        NSLog(@"GL Error = %x", error);
    }
#endif
}

- (void)triggerDrawFrame
{
    if (!_running)
    {
        _running = true;
        dispatch_async(_renderQueue, ^
        {
            // Set the context and framebuffer
            [EAGLContext setCurrentContext:_context];
            
            [self update];
            [self drawFrame];
            [self checkForErrors];
            
            [EAGLContext setCurrentContext:nil];
            
            _running = false;
        });
    }
    else
    {
        _frameDropCounter++;
    }
}

- (void)threadMainLoop
{
    @synchronized(_renderThread)
    {
        @autoreleasepool
        {
            // Set the context and framebuffer
            [EAGLContext setCurrentContext:_context];
            
            // Initialize the controller
            [self initialize];
            
            [EAGLContext setCurrentContext:nil];
            
            
            // Create the render loop and start it
            _renderLoop = [NSRunLoop currentRunLoop];
            
            CADisplayLink* link = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(triggerDrawFrame)];
            [link setFrameInterval:1];
            [link addToRunLoop:_renderLoop forMode:NSDefaultRunLoopMode];
            
            CFRunLoopRun();
            
            [link invalidate];
            _renderLoop = nil;
        }
    }
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchLocation = touches.anyObject;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchLocation = touches.anyObject;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchLocation = nil;
}


#pragma mark - Actions

- (IBAction)toggleMenu:(id)sender
{
    [self.revealViewController revealToggleAnimated:YES];
}


#pragma mark - Gestures

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    float parentViewHeight = self.view.frame.size.height;
    float viewHeight = recognizer.view.frame.size.height;
    float finalViewCenter = parentViewHeight - (viewHeight/2);
    
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    // Store the initial coordinate of the view
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        firstX = recognizer.view.center.x;
        firstY = recognizer.view.center.y;
    }
    
    // Translate the view by usingt the pan gesture
    // (Pan Gesture translatedPoint is absolute, not a delta)
    translatedPoint = CGPointMake(firstX, firstY + translatedPoint.y);
    
    // Limit the maximum height that the overlay can reach (lower Y is higher up)
    if (translatedPoint.y < finalViewCenter)
    {
        float delta = finalViewCenter - translatedPoint.y;
        translatedPoint = CGPointMake(firstX, finalViewCenter);
    }
    
    // Calculate the overlay alpha
    float percent = ((translatedPoint.y - parentViewHeight)/(finalViewCenter - parentViewHeight));
    float alpha = MAX(OverlayMinAlpha, OverlayMaxAlpha * percent);
    
    [recognizer.view setCenter:translatedPoint];
    recognizer.view.backgroundColor = [recognizer.view.backgroundColor colorWithAlphaComponent:alpha];
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint velocity = [recognizer velocityInView:self.view];
        float finalY = translatedPoint.y + (OverlayAnimationSpeed * velocity.y);
        
        if (finalY < finalViewCenter)
        {
            finalY = finalViewCenter;
        }
        else if (finalY > parentViewHeight)
        {
            finalY = parentViewHeight;
        }
        
        float duration = (ABS(velocity.y) * 0.0004);
        percent = ((finalY - parentViewHeight)/(finalViewCenter - parentViewHeight));
        alpha = MAX(OverlayMinAlpha, OverlayMaxAlpha * percent);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [recognizer.view setCenter:CGPointMake(firstX, finalY)];
        recognizer.view.backgroundColor = [recognizer.view.backgroundColor colorWithAlphaComponent:alpha];
        [UIView commitAnimations];
    }
}

@end