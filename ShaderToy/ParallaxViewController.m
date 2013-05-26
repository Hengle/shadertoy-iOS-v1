//
//  ParallaxViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ParallaxViewController.h"
#import "ShaderInformation.h"
#import "ShaderInformationViewController.h"
#import "Plane.h"

#import <QuartzCore/QuartzCore.h>


@interface ParallaxViewController ()

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (void)render:(CADisplayLink *)link;
- (void)renderAsync;

@end

@implementation ParallaxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
        exit(0);
    }
    
    startTime = [NSDate date];
    
    self.view.context = self.context;
    self.view.enableSetNeedsDisplay = NO;
    self.view.contentScaleFactor = 1.0f;
    self.view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    openGLESContextQueue =
    ("com.shadertoy.openGLESContextQueue", NULL);
    frameRenderingSemaphore = dispatch_semaphore_create(1);
    
    [self setupGL];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink setFrameInterval:1];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context)
        {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
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

- (void)setupGL
{
    dispatch_async(openGLESContextQueue, ^
    {
        [EAGLContext setCurrentContext:self.context];
        planeObject = [[Plane alloc] initWithSize:1.0f shaderName:[NSString stringWithFormat:@"Shader_%d", self.index]];
    });
}

- (void)tearDownGL
{
    dispatch_async(openGLESContextQueue, ^
    {
        [EAGLContext setCurrentContext:self.context];
        planeObject = nil;
    });
}

- (void)render:(CADisplayLink *)link
{
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    [self renderAsync];
}

- (void)renderAsync
{
    dispatch_async(openGLESContextQueue, ^
    {
        [EAGLContext setCurrentContext:self.context];
        
        [self update];
        [self.view display];
        
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float width = self.view.drawableWidth;
    float height = self.view.drawableHeight;
    float time = [[NSDate date] timeIntervalSinceDate:startTime];
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, width, height);
    
    [planeObject drawAtResolution:GLKVector3Make(width, height, 0.0f) andTime:time];
}

- (IBAction)toggleMenu:(id)sender
{
    [self.revealViewController revealToggleAnimated:YES];
}

@end