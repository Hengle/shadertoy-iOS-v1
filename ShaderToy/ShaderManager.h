//
//  ShaderManager.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShaderInfo;
@class ShaderManager;

@protocol ShaderManagerDelegate <NSObject>

- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager;

@end

@interface ShaderManager : NSObject
{
    NSMutableArray* pendingShaders;
    NSMutableDictionary* shaderDictionary;
    
    ShaderInfo* _defaultShader;
}

@property (nonatomic, retain) EAGLSharegroup *defaultSharegroup;
@property (nonatomic, readonly) ShaderInfo* defaultShader;
@property (nonatomic, retain) id<ShaderManagerDelegate> delegate;

+ (ShaderManager *)sharedInstance;

- (void)addShader:(ShaderInfo *)shader;
- (void)deferCompilation;

- (void)storeShader:(GLuint)program withName:(NSString *)name;
- (GLuint)getShader:(ShaderInfo *)shader;

@end
