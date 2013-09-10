//
//  ShaderManager.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderManager.h"
#import "ShaderInfo.h"
#import "ChannelResourceManager.h"

@interface ShaderManager ()

- (NSString *)prepareRenderPassCode:(ShaderRenderPass *)renderpass;
- (NSMutableString *)replaceReservedFunctionNames:(NSString *)codeString;
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

- (void)deferCompilation
{
    @synchronized(self)
    {
        // Compile any available shaders
        for (ShaderInfo* shader in pendingShaders)
        {
            if ([shaderDictionary objectForKey:shader.ID] == nil)
            {
                for (ShaderRenderPass* renderpass in shader.renderpasses)
                {
                    GLuint program = [self compileShaderCode:[self prepareRenderPassCode:renderpass]];
                
                    if (program > 0)
                    {
                        [self storeShader:program withName:shader.ID];
                
                        NSLog(@"Created program %u for shader %@", program, shader.name);
                    }
                }
            }
        }
        
        // If we compiled shaders, remove them and notify our delegate
        if (pendingShaders.count > 0)
        {
            [pendingShaders removeAllObjects];
            [_delegate shaderManagerDidFinishCompiling:self];
        }
    }
}

- (ShaderInfo *)defaultShader
{
    if (_defaultShader == nil)
    {
        NSError* error = nil;
        NSString* pathname = [[NSBundle mainBundle] pathForResource:@"logo.json" ofType:nil];
        NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:pathname] options:kNilOptions error:&error];
        
        if (error == nil)
        {
            _defaultShader = [[ShaderInfo alloc] initWithJSONDictionary:dictionary];
        }
    }
    
    return _defaultShader;
}

- (void)addShader:(ShaderInfo *)shader
{
    [pendingShaders addObject:shader];
}

- (void)addShaders:(NSArray *)shaders
{
    [pendingShaders addObjectsFromArray:shaders];
}

- (void)storeShader:(GLuint)program withName:(NSString *)name
{
    [shaderDictionary setObject:[NSNumber numberWithUnsignedInt:program] forKey:name];
}

- (BOOL)shaderExists:(ShaderInfo *)shader
{
    return ([shaderDictionary objectForKey:shader.ID] == nil);
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
        for (ShaderRenderPass* renderpass in shader.renderpasses)
        {
            program = [self compileShaderCode:[self prepareRenderPassCode:renderpass]];
            [self storeShader:program withName:shader.ID];

            NSLog(@"Created program %u for shader %@, renderpass %@", program, shader.name, renderpass.name);
        }
    }
    
    return program;
}

- (NSString *)prepareRenderPassCode:(ShaderRenderPass *)renderpass
{
    // Create the header for this particular shader
    NSMutableString* codeString = [NSMutableString stringWithString:@"// Auto-generated header to define uniforms\n"];
    [codeString appendString:@"precision highp float;\n"];
    [codeString appendString:@"uniform vec3     iResolution;\n"];
    [codeString appendString:@"uniform float    iGlobalTime;\n"];
    [codeString appendString:@"uniform float    iChannelTime[4];\n"];
    [codeString appendString:@"uniform vec3     iChannelResolution[4];\n"];
    [codeString appendString:@"uniform vec4     iMouse;\n\n"];
    [codeString appendString:@"uniform vec4     iDate;\n"];
    [codeString appendString:@"varying vec2     texCoords;\n\n"];
    
    // Create the necessary channels
    for (ShaderInput* input in renderpass.inputs)
    {
        if ([input.type isEqualToString:@"cubemap"])
        {
            [codeString appendFormat:@"uniform samplerCube iChannel%d;\n", input.channel];
        }
        else //if ([input.type isEqualToString:@"texture"] || [input.type isEqualToString:@"music"] || [input.type isEqualToString:@"video"])
        {
            [codeString appendFormat:@"uniform sampler2D iChannel%d;\n", input.channel];
        }
        
        [[ChannelResourceManager sharedInstance] addResource:input.source ofType:input.type];
    }
    
    [codeString appendString:@"\n// Shader code follows\n\n"];
    
    // Append the shader code to the header
    [codeString appendString:renderpass.code];
    
    // Replace reserved strings with prefix
    codeString = [self replaceReservedFunctionNames:codeString];
    
    return codeString;
}

- (NSMutableString *)replaceReservedFunctionNames:(NSString *)codeString
{
    NSError *error = NULL;
    
    // Matches patterns like:
    // noise1(), noise2(a), noise3 ( a, b ) noise4()
    // and adds a Shadertoy_ suffix to the pattern
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(noise[1-4]*[\\s]*\\()" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:codeString options:0 range:NSMakeRange(0, codeString.length) withTemplate:@"Shadertoy_$1"];
    
    if (error != nil)
    {
        NSLog(@"Failed to prefix noise functions! %@", error.localizedDescription);
        
        return [codeString mutableCopy];
    }
    
    return [modifiedString mutableCopy];
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
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:code])
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
        NSLog(@"Shader (%u) compile log:\n%s", *shader, log);
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
        NSLog(@"Program (%u) link log:\n%s", prog, log);
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
