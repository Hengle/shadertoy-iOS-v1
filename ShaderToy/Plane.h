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

@interface Plane : NSObject
{
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _program;
    
    GLuint _positionSlot;
    
    GLuint _resolutionUniform;
    GLuint _timeUniform;
    
    int indicesToDraw;
    
    NSString * _pendingShader;
}

- (id)initShader:(NSString *)name;

- (void)update:(float)deltaTime;
- (void)drawAtResolution:(GLKVector3)resolution andTime:(float)time;

- (void)useShader:(NSString *)name;

@end
