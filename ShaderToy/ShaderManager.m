//
//  ShaderManager.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderManager.h"
#import "ShaderInfo.h"

#import "TextureManager.h"

NSString *const ShaderHeader =
@"// Auto-generated header to define uniforms\n\
precision highp float;\n\
precision lowp int;\n\
uniform highp vec3 iResolution;\n\
uniform float iGlobalTime;\n\
uniform float iChannelTime[4];\n\
uniform sampler2D iChannel0;\n\
uniform sampler2D iChannel1;\n\
uniform sampler2D iChannel2;\n\
uniform sampler2D iChannel3;\n\
uniform highp vec4 iDate;\n\n\
\n\
//Shader code follows\n\n";

@interface ShaderManager ()

- (GLuint)compileShaderFile:(NSString *)fileName;
- (GLuint)compileShaderCode:(NSString *)code;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)code;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation ShaderManager

+ (ShaderManager *)sharedInstance
{
    static ShaderManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [ShaderManager new];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        pendingShaders = [NSMutableArray new];
        shaderDictionary = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)addShader:(ShaderInfo *)shader
{
    [pendingShaders addObject:shader];
}

- (void)deferCompilation
{
    @synchronized(self)
    {
        for (ShaderInfo* shader in pendingShaders)
        {
            if ([shaderDictionary objectForKey:shader.ID] == nil)
            {
                ShaderRenderPass* renderpass = shader.renderpasses[0];
                GLuint program = [self compileShaderCode:renderpass.code];
                
                if (program > 0)
                {
                    [self storeShader:program withName:shader.ID];
                
                    NSLog(@"Created program %u for shader %@", program, shader.name);
                    
                    for (ShaderRenderPass* renderpass in shader.renderpasses)
                    {
                        for (ShaderInput* input in renderpass.inputs)
                        {
                            if ([input.type isEqual: @"texture"])
                            {
                                [[TextureManager sharedInstance] addTexture:input.source];
                            }
                        }
                    }
                }
            }
        }
        
        [pendingShaders removeAllObjects];
    }
}

- (void)storeShader:(GLuint)program withName:(NSString *)name
{
    [shaderDictionary setObject:[NSNumber numberWithUnsignedInt:program] forKey:name];
}

- (GLuint)getShader:(ShaderInfo *)shader
{
    NSNumber* programObject = [shaderDictionary objectForKey:shader.ID];
    GLuint program = 0;
    
    if (programObject != nil)
    {
        program = programObject.unsignedIntValue;
        NSLog(@"Retrieved program %u for shader %@", program, shader.name);
    }
    else
    {
        ShaderRenderPass* renderpass = shader.renderpasses[0];
        program = [self compileShaderCode:renderpass.code];
        [self storeShader:program withName:shader.ID];

        NSLog(@"Created program %u for shader %@", program, shader.name);
    }
    
    return program;
}

- (GLuint)compileShaderFile:(NSString *)fileName
{
    NSString* fragShaderPathname = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString* code = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];
    
    return [self compileShaderCode:code];
}

- (GLuint)compileShaderCode:(NSString *)code
{
    GLuint program, vertShader, fragShader;
    
    // Create and compile vertex shader.
    NSString* vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    NSString* vertCode = [NSString stringWithContentsOfFile:vertShaderPathname encoding:NSUTF8StringEncoding error:nil];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:vertCode])
    {
        NSLog(@"Failed to compile vertex shader");
        return 0;
    }
    
    // Create and compile fragment shader.
    NSString* fragCode = [ShaderHeader stringByAppendingString:code];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:fragCode])
    {
        NSLog(@"Failed to compile fragment shader");
        return 0;
    }
    
    // Create shader program.
    program = glCreateProgram();
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program:%u", program);
        
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
        
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
    }
    else
    {
        // Release vertex and fragment shaders.
        if (vertShader)
        {
            glDetachShader(program, vertShader);
            glDeleteShader(vertShader);
        }
        
        if (fragShader)
        {
            glDetachShader(program, fragShader);
            glDeleteShader(fragShader);
        }
    }
    
    return program;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)code
{
    GLint status;
    const GLchar* source = (GLchar *)code.UTF8String;
    if (!source)
    {
        NSLog(@"Failed to load %d shader", type);
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
