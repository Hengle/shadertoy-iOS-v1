//
//  TextureManager.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ChannelResourceManager : NSObject
{
    NSMutableArray* _pendingResources;
    NSMutableDictionary* _resourceDictionary;
}

+ (ChannelResourceManager *)sharedInstance;

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
- (void)deferredLoading;

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
- (NSData *)getResourceWithName:(NSURL *)name;
- (GLuint)getTextureWithName:(NSURL *)name;
- (GLKVector3)getTextureResolution:(NSURL *)name;

@end
