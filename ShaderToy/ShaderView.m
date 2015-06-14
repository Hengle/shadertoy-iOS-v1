//
//  ShaderView.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/27/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderView.h"

#import <GameKit/GameKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/glext.h>

@interface ShaderView ()
{
    bool _shouldRecreate;
    GLuint  frameBuffer;
    GLuint  renderBuffer;
}

- (void)createBuffers:(EAGLContext *)context;
- (void)destroyBuffers;

@end

@implementation ShaderView

@dynamic layer;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _isSetup = false;
        _shouldRecreate = true;
        self.layer.opaque = YES;
        self.layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO, kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        _isSetup = false;
        _shouldRecreate = true;
    }
    
    return self;
}

- (BOOL)setup:(BOOL)force
{
    if (_isSetup && !force)
    {
        NSLog(@"[ShaderView] Trying to call setup again!");
        return false;
    }
    
    EAGLContext* context = [EAGLContext currentContext];
        
    [self destroyBuffers];
    [self createBuffers:context];
    
    _isSetup = true;
    
    return true;
}

- (void)createBuffers:(EAGLContext *)context
{
    // Create Buffers
    glGenFramebuffers(1, &frameBuffer);
    glGenRenderbuffers(1, &renderBuffer);
    
    // Bind them
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    // Create storage
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
    // Get backing width and height from the buffer
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum frameBufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferStatus != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"[ShaderView] Failed to make complete framebuffer object %x", frameBufferStatus);
    }
    else
    {
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
}

- (void)destroyBuffers
{
    if (frameBuffer)
    {
        glDeleteFramebuffers(1, &frameBuffer);
        frameBuffer = 0;
    }
    
    if (renderBuffer)
    {
        glDeleteRenderbuffers(1, &renderBuffer);
        renderBuffer = 0;
    }
    
    _isSetup = false;
}

- (GLenum)setFramebuffer
{
    if (_shouldRecreate)
    {
        [self setup:true];
        _shouldRecreate = false;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    GLenum frameBufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    return frameBufferStatus;
}

- (void)presentFramebuffer:(EAGLContext *)context
{
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    BOOL success = [context presentRenderbuffer:GL_RENDERBUFFER];
    
    assert(success);
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _shouldRecreate = true;
//    _isSetup = false;
    //[self setup:false];
}

@end
