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
- (UIImage *)flipImageVertically:(UIImage *)originalImage;

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
}

- (UIImage *)captureFramebuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    // Note, replace "_colorRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    GLint x = 0, y = 0;
    NSInteger dataLength = _backingWidth * _backingHeight * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(_backingWidth, _backingHeight, 8, 32, _backingWidth * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // Set the scale parameter to your OpenGL ES view's contentScaleFactor
    // so that you get a high-resolution snapshot when its value is greater than 1.0
    CGFloat scale = self.contentScaleFactor;
    widthInPoints = _backingWidth / scale;
    heightInPoints = _backingHeight / scale;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    return image;
}

- (UIImage *)flipImageVertically:(UIImage *)originalImage
{
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:originalImage];
    UIGraphicsBeginImageContext(tempImageView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, tempImageView.frame.size.height
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    [tempImageView.layer renderInContext:context];
    
    UIImage *flippedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return flippedImage;
}

@end
