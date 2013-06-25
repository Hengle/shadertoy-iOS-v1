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
#import "TextureManager.h"

#import <QuartzCore/QuartzCore.h>


@interface ShaderViewController ()

- (void)tearDown;
- (void)initialize;
- (void)drawFrame;
- (void)triggerDrawFrame;
- (void)threadMainLoop;

@end

@implementation ShaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.sharegroup == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _sharegroup = _context.sharegroup;
    }
    else
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:self.sharegroup];
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
    }
}

- (void)drawFrame
{
    @synchronized(_context)
    {
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
            ShaderParameters* params = [[ShaderParameters alloc] initWithChannelCount:renderpass.inputs.count];
            params.resolution = GLKVector3Make(width, height, 1.0f);
            params.time = time;
            
            // Send touch locations, if valid, otherwise send 0
            if (_touchLocation != nil)
            {
                CGPoint point = [_touchLocation locationInView:self.view];
                params.mouseCoordinates = GLKVector4Make(point.x, point.y, 1.0f, 1.0f);
            }
            else
            {
                params.mouseCoordinates = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
            }
            
            for (ShaderInput* input in renderpass.inputs)
            {
                if ([input.type isEqual: @"texture"])
                {
                    params.channelInfo[input.channel] = [[TextureManager sharedInstance] getTexture:input.source];
                }
            }
            
            // Draw the plane
            [_planeObject draw:params];
        }
        
        [self.view presentFramebuffer];
    }
}

- (void)update
{
    float time = [[NSDate date] timeIntervalSinceDate:_lastFrameTime];
    
    [[ShaderManager sharedInstance] deferCompilation];
    [[TextureManager sharedInstance] deferLoading];
    
    [_planeObject update:time];
    
    _lastFrameTime = [NSDate date];
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
            
#if DEBUG
            GLenum error = glGetError();
            if (error > 0x0)
            {
                NSLog(@"GL Error = %x", error);
            }
#endif
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