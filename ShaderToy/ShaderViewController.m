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

#import <QuartzCore/QuartzCore.h>

@interface ShaderViewController ()

- (void)tearDown;
- (void)initialize;
- (void)update:(float)deltaTime;
- (void)drawFrame:(float)deltaTime;
- (void)calculateFPS:(float)deltaTime;
- (void)checkForErrors;
- (void)triggerDrawFrame;
- (void)threadMainLoop;

@end

@implementation ShaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _context = [[ShaderManager sharedInstance] createNewContext];
    
    if (_context == nil)
    {
        NSLog(@"[ShaderViewController] Failed to create ES context");
        exit(0);
    }
    
    self.shaderView.contentScaleFactor = 1.0f;
    
    _renderThread = nil;
    _animating = false;
    _running = false;
    _initialized = false;
    _overlayVisible = false;
    _frameDropCounter = 0;
    _frameCounter = 0;
    _lastFrameTime = [NSDate date];
    _lastFPSTime = [NSDate date];
    _renderQueue = dispatch_queue_create("com.shadertoy.threadedgcdqueue", DISPATCH_QUEUE_CONCURRENT);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [self setOverlayVisible:false];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    [self flashOverlay:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
//    [self setOverlayVisible:false];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Relayout the view, because we are doing an orientation change
    [self.shaderView setNeedsLayout];
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
        self.shaderView = nil;
        
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

- (void)drawPreviewFrame
{
    NSLog(@"[ShaderViewController] Drawing Preview Frame");
    
    _startTime = [NSDate date];
    _lastFrameTime = [NSDate date];
    _lastFPSTime = [NSDate date];
    
    _animating = true;
    _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop) object:nil];
    
    [_renderThread start];
}

- (void)startAnimation
{
    if (!_animating)
    {
        NSLog(@"[ShaderViewController] Starting animation");
        
        _startTime = [NSDate date];
        _lastFrameTime = [NSDate date];
        _lastFPSTime = [NSDate date];
        
        _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop) object:nil];
        [_renderThread start];
        
        _animating = true;
    }
}

- (void)stopAnimation
{
    if (_animating)
    {
        NSLog(@"[ShaderViewController] Stopping animation");
        
        _animating = false;
        
        if (_renderLoop)
        {
            CFRunLoopStop([_renderLoop getCFRunLoop]);
        }
        
        // Wait for the thread to finish
        @synchronized(_renderThread)
        {
            [_renderThread cancel];
            _renderThread = nil;
        }
    }
}

- (void)setShader:(ShaderInfo *)shader
{
    _currentShader = shader;
    
    // Set the shader information to the overlay
//    [self populateOverlay];
    
    // For bookkeeping purposes
    _renderThread.name = _currentShader.name;
    
    if (_planeObject)
    {
        [_planeObject useShader:_currentShader];
        
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            [_params clearChannels];
            
            // Make sure we are executing the shader parameter in the correct thread
            dispatch_async(_renderQueue, ^
            {
                @synchronized(_context)
                {
                    // Set the context
                    [EAGLContext setCurrentContext:_context];
                    
                    // Inputs are set only on shader initialization, no need to re-set them
                    [self setShaderInputs:renderpass.inputs onParams:_params];
                    
                    // Clear the context
                    [EAGLContext setCurrentContext:nil];
                }
            });
        }
    }
    
    NSLog(@"[ShaderViewController] Setting shader to %@", shader.name);
}

- (void)setShaderInputs:(NSArray *)inputs onParams:(ShaderParameters *)params
{
    for (ShaderInput *input in inputs)
    {
        if ([input.type isEqualToString:@"texture"])
        {
            GLuint textureID = [[ChannelResourceManager sharedInstance] getTextureWithName:input.source];
            
            if (textureID > 0)
            {
                GLKVector3 resolution = [[ChannelResourceManager sharedInstance] getTextureResolution:input.source];
                
                params.channelInfo[input.channel] = textureID;
                [params setChannel:input.channel resolution:resolution];
                
                NSLog(@"[ShaderViewController] Setting input channel %d to texture %d, resolution %f x %f", input.channel, params.channelInfo[input.channel], params.channelResolution[input.channel + 0], params.channelResolution[input.channel + 1]);
            }
        }
        else
        {
            params.channelInfo[input.channel] = 0;
            [params setChannel:input.channel resolution:GLKVector3Make(0.0f, 0.0f, 1.0f)];
        }
    }
}

- (void)setFPS:(float)fps
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _fpsLabel.text = [NSString stringWithFormat:@"%2.f FPS", fps];
                   });
}

- (void)populateOverlay
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _nameLabel.text = _currentShader.name;
                       _authorLabel.text = _currentShader.username;
                       _descriptionLabel.text = _currentShader.descriptionString;
                       
                       NSMutableString* tags = [NSMutableString new];
                       for (int i = 0; i < self.currentShader.tags.count; i++)
                       {
                           if (i < self.currentShader.tags.count - 1)
                           {
                               [tags appendFormat:@"%@, ", self.currentShader.tags[i]];
                           }
                           else
                           {
                               [tags appendString:self.currentShader.tags[i]];
                           }
                       }
                       
                       _tagsLabel.text = tags;
                       
                       [_likeButton setTitle:[NSString stringWithFormat:@"%d", self.currentShader.likes] forState:UIControlStateNormal];
                       [_viewsButton setTitle:[NSString stringWithFormat:@"%d", self.currentShader.viewed] forState:UIControlStateNormal];
                   });
}

- (void)setOverlayVisible:(BOOL)visible
{
    NSLog(@"[ShaderViewController] [Set - %@] Overlay %@", self.currentShader.name, visible ? @"visible" : @"hidden");
    
    self.overlayView.alpha = (visible ? 1.0f : 0.0f);
    _overlayVisible = visible;
}

- (IBAction)toggleOverlay:(id)sender
{
    bool enabled = !_overlayVisible;
    if (!self.currentShader.removeoverlay)
    {
        NSLog(@"[ShaderViewController] [Toggle - %@] Overlay %@", self.currentShader.name, enabled ? @"visible" : @"hidden");
        
        [UIView animateWithDuration:0.5f delay:1.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.overlayView.alpha = (enabled ? 1.0f : 0.0f);
        } completion:^(BOOL finished) {
            _overlayVisible = enabled;
        }];
    }
}

- (IBAction)flashOverlay:(id)sender
{
    if (!self.currentShader.removeoverlay && !_overlayVisible)
    {
        NSLog(@"[ShaderViewController] [Flash - %@] Overlay %@", self.currentShader.name, _overlayVisible ? @"visible" : @"hidden");
        
        // Animate the overlay
        [UIView animateWithDuration:0.5f delay:1.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.overlayView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            // When alpha is 1.0, set it to visible
            _overlayVisible = true;
            NSLog(@"[ShaderViewController] [Flash - %@] Overlay %@", self.currentShader.name, _overlayVisible ? @"visible" : @"hidden");
            [UIView animateWithDuration:0.5f delay:5.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.overlayView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                // When alpha is 0.0, set it to invisible
                _overlayVisible = false;
                NSLog(@"[ShaderViewController] [Flash - %@] Overlay %@", self.currentShader.name, _overlayVisible ? @"visible" : @"hidden");
            }];
        }];
    }
}

- (IBAction)share:(id)sender
{
    UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"Check out %@ by %@ in Shadertoy!", self.currentShader.name, self.currentShader.username], [NSString stringWithFormat:@"https://www.shadertoy.com/view/%@", self.currentShader.ID]] applicationActivities:nil];
    activityController.popoverPresentationController.sourceView = self.shareButton;
    
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)like:(id)sender
{
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
        _initialized = true;
        _planeObject = [[Plane alloc] initWithShader:_currentShader];
        
        // Create a params object for this shader
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            _params = [[ShaderParameters alloc] init];
            
            // Inputs are set only on initialization, no need to re-set them
            [self setShaderInputs:renderpass.inputs onParams:_params];
        }
    }
}

- (void)drawFrame:(float)deltaTime
{
    GLenum frameBufferStatus = [self.shaderView setFramebuffer];
    
    if (frameBufferStatus == GL_FRAMEBUFFER_COMPLETE)
    {
        // Calculate the width and height of the view
        float width = self.shaderView.backingWidth;
        float height = self.shaderView.backingHeight;
        
        // Clear the context
        glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glViewport(0, 0, width, height);
        
        // Iterate over renderpasses and send the appropriate values to the shader
        for (int i = 0; i < _currentShader.renderpasses.count; i++)
        {
            // Setup the parameters that are sent to the shader
            _params.resolution = GLKVector3Make(width, height, 1.0f);
            _params.time = deltaTime;
            
            // Send touch locations, if valid, otherwise send 0
            if (_touchLocation != nil)
            {
                CGPoint point = [_touchLocation locationInView:self.shaderView];
                _params.mouseCoordinates = GLKVector4Make(point.x, self.shaderView.bounds.size.height - point.y, 1.0f, 1.0f);
            }
            else
            {
                _params.mouseCoordinates = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
            }
            
            // Draw the plane
            [_planeObject draw:_params];
        }
        
        [self.shaderView presentFramebuffer:_context];
    }
    else
    {
        NSLog(@"[ShaderViewController] Framebuffer is not ready, skipping draw!");
    }
}

- (void)update:(float)deltaTime
{
    [_planeObject update:deltaTime];
    
    [self calculateFPS:deltaTime];
    
    _lastFrameTime = [NSDate date];
}

- (void)calculateFPS:(float)deltaTime
{
    _frameCounter++;
    
    if (deltaTime > 0.5f)
    {
        float fps = _frameCounter / deltaTime;
        if (_frameCounter > 1 && fps < 10.0f)
        {
            [self stopAnimation];
            NSLog(@"[ShaderViewController] Paused");
        }
        
        [self setFPS:fps];
        
        _frameCounter = 0;
        _lastFPSTime = [NSDate date];
    }
}

- (void)checkForErrors
{
#if DEBUG
    GLenum error = glGetError();
    if (error > 0x0)
    {
        NSLog(@"[ShaderViewController] %@ GL Error = %x", self.currentShader.name, error);
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
            @synchronized(_context)
            {
                // Set the context and framebuffer
                [EAGLContext setCurrentContext:_context];
                
                // Calculate the time since since rendering start
                float deltaTime = ABS([_startTime timeIntervalSinceNow]);
                
                [self update:deltaTime];
                [self drawFrame:deltaTime];
                [self checkForErrors];
                
                [EAGLContext setCurrentContext:nil];
            }
            
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
            @synchronized(_context)
            {
                // Set the context and framebuffer
                [EAGLContext setCurrentContext:_context];
                
                // Initialize the controller
                [self initialize];
                
                [EAGLContext setCurrentContext:nil];
            }
            
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

@end