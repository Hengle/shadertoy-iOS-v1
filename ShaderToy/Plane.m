//
//  Plane.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "Plane.h"
#import "ShaderManager.h"
#import "ShaderInfo.h"


@interface Plane ()

- (void)loadShader:(ShaderInfo *)shader;

@end

@implementation Plane

- (id)initWithShader:(ShaderInfo *)shader
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
        
        [self loadShader:shader];
        
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
    if (_pendingShader != nil)
    {
        [self loadShader:_pendingShader];
        _pendingShader = nil;
    }
}

- (void)draw:(UniformParams *)params
{
    if (_program)
    {
        glUseProgram(_program);
        
        glUniform3fv(_resolutionUniform, 3, params->resolution.v);
        glUniform1f(_timeUniform, params->time);
        glUniform1fv(_channelTimeUniform, 4, params->channelTime);
        glUniform4fv(_mouseUniform, 4, params->mouseCoordinates.v);
        glUniform4fv(_dateUniform, 4, params->date.v);
        
        for (int i = 0; i < 4; i++)
        {
            glUniform1i(_channelUniform[i], params->channelInfo[i]);
        }
        
        glBindVertexArrayOES(_vertexArray);
        
        glDrawElements(GL_TRIANGLES, indicesToDraw, GL_UNSIGNED_SHORT, 0); 
    }
}

- (void)useShader:(ShaderInfo *)shader
{
    _pendingShader = shader;
}

- (void)loadShader:(ShaderInfo *)shader;
{
    GLuint program = [[ShaderManager sharedInstance] getShader:shader];
    
    _program = program;
    glUseProgram(_program);
    
    _positionSlot = glGetAttribLocation(_program, "position");
    
    _resolutionUniform = glGetUniformLocation(_program, "iResolution");
    _timeUniform = glGetUniformLocation(_program, "iGlobalTime");
    _channelTimeUniform = glGetUniformLocation(_program, "iChannelTime");
    _mouseUniform = glGetUniformLocation(_program, "iMouse");
    _dateUniform = glGetUniformLocation(_program, "iDate");
    
    for (int i = 0; i < 4; i++)
    {
        NSString* channel = [NSString stringWithFormat:@"iChannel%d", i];
        _channelUniform[i] = glGetUniformLocation(_program, channel.UTF8String);
    }
}

@end
