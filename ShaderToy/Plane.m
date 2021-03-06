//
//  Plane.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "Plane.h"
#import "ShaderManager.h"
#import "ShaderInfo.h"

#import <OpenGLES/ES2/glext.h>

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
        
        _indicesToDraw = 6;
        
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

- (void)draw:(ShaderParameters *)params
{
    if (_program)
    {
        glUseProgram(_program);
        
        // Pixel shader uniforms
        // Check to see if the uniform is valid (invalid when it doesn't exist ie. -1)
        if (_resolutionUniform != -1)
            glUniform3fv(_resolutionUniform, 1, params.resolution.v);
        
        if (_timeUniform != -1)
            glUniform1f(_timeUniform, params.time);
        
        if (_channelTimeUniform != -1)
            glUniform1fv(_channelTimeUniform, 4, params.channelTime);
        
        if (_channelResolutionUniform != -1)
            glUniform3fv(_channelResolutionUniform, 4, params.channelResolution);
        
        if (_mouseUniform != -1)
            glUniform4fv(_mouseUniform, 1, params.mouseCoordinates.v);
        
        if (_dateUniform != -1)
            glUniform4fv(_dateUniform, 1, params.date.v);
        
        // Go through our uniform channel params and set the ones we need
        for (int i = 0; i < 4; i++)
        {
            glActiveTexture(GL_TEXTURE0 + i);
            glBindTexture(GL_TEXTURE_2D, 0);
            
            if (_channelUniform[i] != -1)
            {
                if (params.channelInfo[i] > 0)
                {
                    glBindTexture(GL_TEXTURE_2D, params.channelInfo[i]);
                    
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                    
                    glUniform1i(_channelUniform[i], i);
                    
                    //NSLog(@"Binding texture %d to slot %d, uniform %d to unit %d", params.channelInfo[i], GL_TEXTURE0 + i, _channelUniform[i], i);
                }
            }
        }
        
        glBindVertexArrayOES(_vertexArray);
        
        glDrawElements(GL_TRIANGLES, _indicesToDraw, GL_UNSIGNED_SHORT, 0);
    }
}

- (void)useShader:(ShaderInfo *)shader
{
    _pendingShader = shader;
}

- (void)loadShader:(ShaderInfo *)shader;
{
    // Clear the channel uniforms
    for (int i = 0; i < 4; i++)
    {
        _channelUniform[i] = -1;
    }
    
    for (ShaderRenderPass* renderpass in shader.renderpasses)
    {
        // Retrieve the program from the ShaderManager (and sharegroup by extension)
        GLuint program = [[ShaderManager sharedInstance] getShader:shader];
    
        _program = program;
        
        // Position uniform
        _positionSlot = glGetAttribLocation(_program, "position");
        
        // Frag Shader uniforms
        _resolutionUniform = glGetUniformLocation(_program, "iResolution");
        _timeUniform = glGetUniformLocation(_program, "iGlobalTime");
        _channelTimeUniform = glGetUniformLocation(_program, "iChannelTime");
        _channelResolutionUniform = glGetUniformLocation(_program, "iChannelResolution");
        _mouseUniform = glGetUniformLocation(_program, "iMouse");
        _dateUniform = glGetUniformLocation(_program, "iDate");
    
        // Read the uniform locations for the existing channels
        for (ShaderInput* input in renderpass.inputs)
        {
            NSString* channel = [NSString stringWithFormat:@"iChannel%d", input.channel];
            GLuint uniform = glGetUniformLocation(_program, channel.UTF8String);
            _channelUniform[input.channel] = uniform;
        }
    }
}

@end
