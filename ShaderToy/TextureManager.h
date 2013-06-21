//
//  TextureManager.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface TextureManager : NSObject
{
    NSMutableArray* pendingTextures;
    NSMutableDictionary* textureDictionary;
}

+ (TextureManager *)sharedInstance;

- (void)addTexture:(NSURL *)path;
- (void)deferLoading;

- (void)storeTexture:(GLKTextureInfo *)texture withName:(NSString *)name;
- (GLuint)getTexture:(NSURL *)path;

@end
