//
//  ParallaxViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderViewController.h"
#import "ShaderView.h"
#import "ShaderInformation.h"
#import "ShaderInformationViewController.h"
#import "Plane.h"

#import <QuartzCore/QuartzCore.h>


@interface ShaderViewController ()

- (void)tearDown;
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

- (void)setShader:(NSString *)name
{
    _currentShader = name;
    
    if (_planeObject)
    {
        [_planeObject useShader:name];
    }
    
    NSLog(@"Settings shader to %@", name);
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

- (void)drawFrame
{
    @synchronized(_context)
    {
        [EAGLContext setCurrentContext:_context];
        
        [self.view setFramebuffer];
        
        if (!_initialized)
        {
            self.view.context = _context;
            _initialized = true;
            _planeObject = [[Plane alloc] initShader:_currentShader];
        }
        
        float width = self.view.backingWidth;
        float height = self.view.backingHeight;
        float time = [[NSDate date] timeIntervalSinceDate:_startTime];
        
        [self update];
        
        glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glViewport(0, 0, width, height);
        
        [_planeObject drawAtResolution:GLKVector3Make(width, height, 0.0f) andTime:time];
        
        [self.view presentFramebuffer];
        
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)triggerDrawFrame
{
    if (!_running)
    {
        _running = true;
        dispatch_async(_renderQueue, ^
        {
            [self drawFrame];
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

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [_planeObject update:1.0f];
}

- (IBAction)toggleMenu:(id)sender
{
    [self.revealViewController revealToggleAnimated:YES];
}

@end