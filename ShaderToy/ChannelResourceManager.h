//
//  TextureManager.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ChannelResourceManager : NSObject
{
    NSMutableArray* pendingResources;
    NSMutableDictionary* resourceDictionary;
}

+ (ChannelResourceManager *)sharedInstance;

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
- (void)deferLoading;

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
- (GLuint)getResourceWithName:(NSURL *)name;

@end
