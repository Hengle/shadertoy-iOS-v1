//
//  ShaderManager.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ShaderInfo;

@interface ShaderManager : NSObject
{
    NSMutableArray* pendingShaders;
    NSMutableDictionary* shaderDictionary;
}

+ (ShaderManager *)sharedInstance;

- (void)addShader:(ShaderInfo *)shader;
- (void)deferCompilation;

- (void)storeShader:(GLuint)program withName:(NSString *)name;
- (GLuint)getShader:(ShaderInfo *)shader;

@end
