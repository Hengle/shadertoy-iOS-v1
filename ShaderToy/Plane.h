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
    float pad1;         // Align normals to 4-byte word boundary
    float normal[3];
    float pad2;         // Align color to 4-byte word boundary
    float color[4];
    float uv[2];
} Vertex;

@interface Plane : NSObject
{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _program;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    
    GLuint _resolutionUniform;
    GLuint _timeUniform;
    
    int indicesToDraw;
    
    NSString * _pendingShader;
}

- (id)initWithSize:(float)size;

- (void)update:(float)deltaTime;
- (void)drawAtResolution:(GLKVector3)resolution andTime:(float)time;

- (void)useShader:(NSString *)name;

@end
