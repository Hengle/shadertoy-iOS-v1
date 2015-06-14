//
//  ShaderManager.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShaderInfo;
@class ShaderManager;

static NSString* _shaderHeader = @"// Auto-generated header to define uniforms\n"
"#ifdef GL_ES\n"
"#ifdef GL_OES_standard_derivatives\n"
"#extension GL_OES_standard_derivatives : enable\n"
"#endif\n"
"#endif\n"
"precision highp float;\n"
"uniform vec3 iResolution;\n"
"uniform float iGlobalTime;\n"
"uniform float iChannelTime[4];\n"
"uniform float iSampleRate;\n"
"uniform vec3 iChannelResolution[4];\n"
"uniform vec4 iMouse;\n\n"
"uniform vec4 iDate;\n"
"varying vec2 texCoords;\n\n";

static NSString* _shaderMain = @"\nvoid main( void ){vec4 color; mainImage( color, gl_FragCoord.xy ); color.w = 1.0; gl_FragColor = color;}\n";

@protocol ShaderManagerDelegate <NSObject>

@optional
- (void)shaderManagerDidStartCompiling:(ShaderManager *)manager;
- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager;

@end

@interface ShaderManager : NSObject

@property (nonatomic, readonly) ShaderInfo* defaultShader;
@property (nonatomic, retain) id<ShaderManagerDelegate> delegate;

+ (ShaderManager *)sharedInstance;
- (EAGLContext *)createNewContext;

- (void)addShader:(ShaderInfo *)shader;
- (void)addShaders:(NSArray *)shaders;
- (void)deferredCompilation;

- (void)storeShader:(GLuint)program withName:(NSString *)name;
- (BOOL)shaderExists:(ShaderInfo *)shader;
- (GLuint)getShader:(ShaderInfo *)shader;

@end
