//
//  Plane.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "Plane.h"
#import "ShaderManager.h"

@interface Plane ()

- (void)loadShader:(NSString *)name;

@end

@implementation Plane

- (id)initShader:(NSString *)name;
{
    self = [super init];
    if (self)
    {
        Vertex vertices[] =
        {
            {{1.0f,  -1.0f, 0}},
            {{1.0f,   1.0f, 0}},
            {{-1.0f,  1.0f, 0}},
            {{-1.0f, -1.0f, 0}}
        };
        
        GLushort indices[] =
        {
            0, 1, 2,
            2, 3, 0,
        };
        
        indicesToDraw = 6;
        
        [self loadShader:name];
        
        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), &vertices, GL_STATIC_DRAW);
        
        glGenBuffers(1, &_indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), &indices, GL_STATIC_DRAW);
        
        // Enable the Position attribute
        glEnableVertexAttribArray(_positionSlot);
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, position));
        
        glBindVertexArrayOES(0);
    }
    
    return self;
}

- (void)dealloc
{
    // Delete our buffers when we are done
    glDeleteBuffers(1, &_vertexArray);
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    if (_program)
    {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)update:(float)deltaTime
{
    [[ShaderManager sharedInstance] deferCompilation];
    
    if (_pendingShader != nil)
    {
        [self loadShader:_pendingShader];
        _pendingShader = nil;
    }
}

- (void)drawAtResolution:(GLKVector3)resolution andTime:(float)time
{
    if (_program)
    {
        glUseProgram(_program);
        
        glUniform3f(_resolutionUniform, resolution.x, resolution.y, resolution.z);
        glUniform1f(_timeUniform, time);
        
        glBindVertexArrayOES(_vertexArray);
        
        glDrawElements(GL_TRIANGLES, indicesToDraw, GL_UNSIGNED_SHORT, 0);
    }
}

- (void)useShader:(NSString *)name
{
    _pendingShader = name.lastPathComponent;
}

- (void)loadShader:(NSString *)name
{
    GLuint program = [[ShaderManager sharedInstance] getShaderWithName:name];
    
    _program = program;
    glUseProgram(_program);
    
    _positionSlot = glGetAttribLocation(_program, "position");
    
    _resolutionUniform = glGetUniformLocation(_program, "iResolution");
    _timeUniform = glGetUniformLocation(_program, "iGlobalTime");
}

@end
