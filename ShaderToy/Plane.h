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

typedef struct
{
    GLKVector3 resolution;
    float time;
    float channelTime[4];
    GLKVector4 mouseCoordinates;
    GLuint channelInfo[4];
    GLKVector4 date;
} UniformParams;

@class ShaderInfo;

@interface Plane : NSObject
{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _program;
    
    GLuint _positionSlot;
    GLuint _resolutionUniform;
    GLuint _timeUniform;
    GLuint _channelTimeUniform;
    GLuint _mouseUniform;
    GLuint _channelUniform[4];
    GLuint _dateUniform;
    
    int indicesToDraw;
    
    ShaderInfo * _pendingShader;
}

- (id)initWithShader:(ShaderInfo *)shader;

- (void)update:(float)deltaTime;
- (void)draw:(UniformParams *)params;

- (void)useShader:(ShaderInfo *)shader;

@end
