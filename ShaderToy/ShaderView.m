//
//  ShaderView.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/27/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderView.h"

#import <GameKit/GameKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ShaderView ()
{
    GLuint  frameBuffer;
    GLuint  renderBuffer;
}

- (void)createBuffers;
- (void)destroyBuffers;

@end

@implementation ShaderView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.layer.opaque = YES;
        self.layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    }
    
    return self;
}



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
    }
    
    return self;
}

- (void)setContext:(EAGLContext *)context
{
    _context = context;
    
    [self createBuffers];
}

- (void)createBuffers
{
    // Create Buffers
    glGenFramebuffers(1, &frameBuffer);
    glGenRenderbuffers(1, &renderBuffer);
    
    // Bind them
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    // Create storage
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
    //
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum frameBufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferStatus != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", frameBufferStatus);
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
}

- (void)setFramebuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
}

- (void)presentFramebuffer
{
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    BOOL success = [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    assert(success);
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_context == nil)
    {
        return;
    }
    
    @synchronized(_context)
    {
        [EAGLContext setCurrentContext:_context];
        
        [self destroyBuffers];
        [self createBuffers];
        
        [EAGLContext setCurrentContext:nil];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end