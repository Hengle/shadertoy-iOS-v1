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
{
    // Multithreading support
    EAGLContext* _context;
    NSThread* _managerThread;
    
    ShaderInfo* _defaultShader;
    NSMutableArray* _pendingShaders;
    NSMutableDictionary* _shaderDictionary;
    EAGLSharegroup *defaultSharegroup;
}

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
        _pendingShaders = [NSMutableArray new];
        _shaderDictionary = [NSMutableDictionary new];
        
        _context = [self createNewContext];
        
        _managerThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop) object:nil];
        [_managerThread start];
    }
    
    return self;
}

- (void)threadMainLoop
{
    NSLog(@"[ShaderManager] Starting manager thread");
    
    @synchronized(_managerThread)
    {
        @autoreleasepool
        {
            while (true)
            {
                [EAGLContext setCurrentContext:_context];
                
                NSArray* newShaders;
                NSMutableArray* shadersToCompile = [NSMutableArray new];
                @synchronized(_pendingShaders)
                {
                    newShaders = [_pendingShaders copy];
                    [_pendingShaders removeAllObjects];
                    
                    // Figure out which shaders need to be compiled and create a new list to send to the shader manager
                    for (ShaderInfo* shader in newShaders)
                    {
                        // Check that the shader does not exist
                        if (![[ShaderManager sharedInstance] shaderExists:shader])
                        {
                            [shadersToCompile addObject:shader];
                        }
                    }
                }
                
                // Compile any available shaders
                for (ShaderInfo* shader in shadersToCompile)
                {
                    if ([_shaderDictionary objectForKey:shader.ID] == nil)
                    {
                        for (ShaderRenderPass* renderpass in shader.renderpasses)
                        {
                            GLuint program = [self compileShaderCode:[self prepareRenderPassCode:renderpass]];
                            
                            if (program > 0)
                            {
                                [self storeShader:program withName:shader.ID];
                                
                                NSLog(@"[ShaderManager] Created program %u for shader %@", program, shader.name);
                            }
                        }
                    }
                }
                
                if (newShaders.count > 0)
                {
                    // If we compiled shaders, remove them and notify our delegate
                    [_delegate shaderManagerDidFinishCompiling:self shaders:newShaders];
                }
                
                glFlush();
                
                [EAGLContext setCurrentContext:nil];
                [NSThread sleepForTimeInterval:1.0f];
            }
        }
    }
    
    NSLog(@"[ShaderManager] Finished running thread");
}

- (EAGLContext *)createNewContext
{
    EAGLContext *context = nil;
    if (defaultSharegroup == nil)
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if (context == nil)
        {
            context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        }
        
        defaultSharegroup = context.sharegroup;
    }
    else
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:defaultSharegroup];
        if (context == nil)
        {
            context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:defaultSharegroup];
        }
    }

    return context;
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
    @synchronized(_pendingShaders)
    {
        [_pendingShaders addObject:shader];
    }
}

- (void)addShaders:(NSArray *)shaders
{
    @synchronized(_pendingShaders)
    {
        [_pendingShaders addObjectsFromArray:shaders];
    }
}

- (void)storeShader:(GLuint)program withName:(NSString *)name
{
    [_shaderDictionary setObject:[NSNumber numberWithUnsignedInt:program] forKey:name];
}

- (BOOL)shaderExists:(ShaderInfo *)shader
{
    NSNumber* program = [_shaderDictionary objectForKey:shader.ID];
    
    return (program != nil);
}

- (GLuint)getShader:(ShaderInfo *)shader
{
    NSNumber* programObject = [_shaderDictionary objectForKey:shader.ID];
    GLuint program = 0;
    
    if (programObject != nil)
    {
        program = programObject.unsignedIntValue;
        NSLog(@"[ShaderManager] Retrieved program %u for shader %@", program, shader.name);
    }
    else
    {
        for (ShaderRenderPass* renderpass in shader.renderpasses)
        {
            program = [self compileShaderCode:[self prepareRenderPassCode:renderpass]];
            [self storeShader:program withName:shader.ID];

            NSLog(@"[ShaderManager] Created program %u for shader %@, renderpass %@", program, shader.name, renderpass.name);
        }
    }
    
    return program;
}

- (NSString *)prepareRenderPassCode:(ShaderRenderPass *)renderpass
{
    // Create the header for this particular shader
    NSMutableString* codeString = [NSMutableString stringWithString:_shaderHeader];
    
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
        
        if (![input.type isEqualToString:@"keyboard"])
        {
            [[ChannelResourceManager sharedInstance] addResource:input.source ofType:input.type];
        }
    }
    
    [codeString appendString:@"\n// Shader code follows\n\n"];
    
    // Append the shader code to the header
    [codeString appendString:renderpass.code];
    
    // Append the header that will call the main function
    [codeString appendString:_shaderMain];
    
    // Replace reserved strings with prefix
    codeString = [self replaceReservedFunctionNames:codeString];
    
    return codeString;
}

- (NSMutableString *)replaceReservedFunctionNames:(NSString *)codeString
{
    NSError *error = NULL;
    
    // Matches patterns like:
    // noise1(), noise2(a), noise3( a, b ) noise4()
    // and adds a Shadertoy_ suffix to the pattern
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(noise[1-4]*[\\s]*\\()" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:codeString options:0 range:NSMakeRange(0, codeString.length) withTemplate:@"Shadertoy_$1"];
    
    if (error != nil)
    {
        NSLog(@"[ShaderManager] Failed to prefix noise functions! %@", error.localizedDescription);
        
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
        NSLog(@"[ShaderManager] Failed to compile vertex shader");
        return 0;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:code])
    {
        NSLog(@"[ShaderManager] Failed to compile fragment shader");
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
        NSLog(@"[ShaderManager] Failed to link program:%u", program);
        
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
        NSLog(@"[ShaderManager] Failed to load %d shader", type);
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
        NSLog(@"[ShaderManager] Shader (%u) compile log:\n%s", *shader, log);
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
        NSLog(@"[ShaderManager] Program (%u) link log:\n%s", prog, log);
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
        NSLog(@"[ShaderManager] Program validate log:\n%s", log);
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
