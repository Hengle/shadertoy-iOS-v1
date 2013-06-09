//
//  ShaderManager.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderManager.h"

@interface ShaderManager ()

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
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
        shaderDictionary = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)storeShader:(GLuint)program withName:(NSString *)name
{
    [shaderDictionary setObject:[NSNumber numberWithUnsignedInt:program] forKey:name];
}

- (GLuint)getShaderWithName:(NSString *)name
{
    NSNumber* programObject = [shaderDictionary objectForKey:name];
    GLuint program = 0;
    
    if (programObject != nil)
    {
        NSLog(@"Retrieved program %d for shader %@", program, name);
        program = programObject.unsignedIntValue;
    }
    else
    {
        GLuint vertShader, fragShader;
        NSString *vertShaderPathname, *fragShaderPathname;
            
        // Create and compile vertex shader.
        vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
        if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
        {
            NSLog(@"Failed to compile vertex shader");
            return 0;
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
        {
            NSLog(@"Failed to compile fragment shader %@", name);
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
            NSLog(@"Failed to link program: %@(%d)", name, program);
            
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
        
        NSLog(@"Created program %d for shader %@", program, name);
        
        programObject = [NSNumber numberWithUnsignedInt:program];
        [shaderDictionary setObject:programObject forKey:name];
    }
    
    return program;
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
