//
//  ShaderManager.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/8/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShaderManager : NSObject
{
    NSMutableDictionary* shaderDictionary;
}

+ (ShaderManager *)sharedInstance;

- (void)storeShader:(GLuint)program withName:(NSString *)name;
- (GLuint)getShaderWithName:(NSString *)name;

@end
