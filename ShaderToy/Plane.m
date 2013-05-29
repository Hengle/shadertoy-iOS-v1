//
//  Plane.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "Plane.h"

@interface Plane ()

- (BOOL)loadShader:(NSString *)name;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation Plane

- (id)init
{
    return [self initWithSize:1.0f];
}

- (id)initWithSize:(float)size
{
    self = [super init];
    if (self)
    {
        Vertex vertices[] =
        {
            {{size,  -size, 0}, 0, {0, 1, 0}, 0, {1.0f, 0.0f, 0.0f, 1.0f}, {1.0f, 1.0f}},
            {{size,   size, 0}, 0, {0, 1, 0}, 0, {0.0f, 1.0f, 0.0f, 1.0f}, {1.0f, 0.0f}},
            {{-size,  size, 0}, 0, {0, 1, 0}, 0, {0.0f, 0.0f, 1.0f, 1.0f}, {0.0f, 0.0f}},
            {{-size, -size, 0}, 0, {0, 1, 0}, 0, {0.0f, 0.0f, 0.0f, 1.0f}, {0.0f, 1.0f}}
        };
        
        GLushort indices[] =
        {
            0, 1, 2,
            2, 3, 0,
        };
        
        indicesToDraw = 6;
        
        [self loadShader:@"Shader_0.fsh"];
        
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
        
        // Enable the Color Attribute
        glEnableVertexAttribArray(_colorSlot);
        glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, color));
        
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
        if (_program)
        {
            glDeleteProgram(_program);
            _program = 0;
        }
        
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

- (BOOL)loadShader:(NSString *)name
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader %@", name);
        return NO;
    }
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Link program.
    if (![self linkProgram:_program])
    {
        NSLog(@"Failed to link program: %@(%d)", name, _program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (_program)
        {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    glUseProgram(_program);
    
    _positionSlot = glGetAttribLocation(_program, "position");
    _colorSlot = glGetAttribLocation(_program, "color");
    
    _resolutionUniform = glGetUniformLocation(_program, "iResolution");
    _timeUniform = glGetUniformLocation(_program, "iGlobalTime");
    
    // Release vertex and fragment shaders.
    if (vertShader)
    {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader)
    {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        return NO;
    }
    
    return YES;
}

@end
