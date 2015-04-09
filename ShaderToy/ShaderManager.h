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
- (void)deferCompilation;

- (void)storeShader:(GLuint)program withName:(NSString *)name;
- (BOOL)shaderExists:(ShaderInfo *)shader;
- (GLuint)getShader:(ShaderInfo *)shader;

@end
