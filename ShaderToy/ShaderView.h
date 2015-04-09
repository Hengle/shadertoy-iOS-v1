//
//  ShaderView.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/27/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CAEAGLLayer;

@interface ShaderView : UIView

@property (readonly) GLint   backingWidth;
@property (readonly) GLint   backingHeight;
@property (nonatomic,readonly,retain) CAEAGLLayer *layer;
@property (strong, nonatomic) EAGLContext *context;

- (BOOL)setup:(BOOL)force;
- (void)setFramebuffer;
- (void)presentFramebuffer;

@end
