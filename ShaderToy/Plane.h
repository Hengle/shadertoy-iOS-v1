//
//  Plane.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef struct
{
    float position[3];
} Vertex;

@class ShaderInfo;
@class ShaderParameters;

@interface Plane : NSObject
{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _program;
    
    GLint _positionSlot;
    GLint _resolutionUniform;
    GLint _timeUniform;
    GLint _channelTimeUniform;
    GLint _mouseUniform;
    GLint _channelUniform[4];
    GLint _dateUniform;
    
    int indicesToDraw;
    
    ShaderInfo * _pendingShader;
}

- (id)initWithShader:(ShaderInfo *)shader;

- (void)update:(float)deltaTime;
- (void)draw:(ShaderParameters *)params;

- (void)useShader:(ShaderInfo *)shader;

@end
