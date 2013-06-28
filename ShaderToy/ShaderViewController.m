//
//  ParallaxViewController.m
//  ShaderToy
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

#import <QuartzCore/QuartzCore.h>


@interface ShaderViewController ()

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
    
    if (_planeObject)
    {
        [_planeObject useShader:shader];
        
        [_params clearChannels];
        
        for (ShaderRenderPass* renderpass in _currentShader.renderpasses)
        {
            // Inputs are only set only on initialization, no need to re-set them
            for (ShaderInput* input in renderpass.inputs)
            {
                if ([input.type isEqual: @"texture"])
                {
                    _params.channelInfo[input.channel] = [[ChannelResourceManager sharedInstance] getResourceWithName:input.source];
                }
            }
        }
    }
    
    NSLog(@"Settings shader to %@", shader.ID);
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
            _params = [[ShaderParameters alloc] initWithChannelCount:renderpass.inputs.count];
            
            [_params clearChannels];
            
            // Inputs are only set only on initialization, no need to re-set them
            for (ShaderInput* input in renderpass.inputs)
            {
                if ([input.type isEqual: @"texture"])
                {
                    _params.channelInfo[input.channel] = [[ChannelResourceManager sharedInstance] getResourceWithName:input.source];
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
                _params.mouseCoordinates = GLKVector4Make(point.x, point.y, 1.0f, 1.0f);
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

@end