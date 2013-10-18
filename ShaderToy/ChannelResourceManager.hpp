//
//  TextureManager.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "AudioController.hpp"


@interface ChannelResourceManager : NSObject <AudioControllerDelegate>
{
    NSMutableArray* _pendingResources;
    NSMutableDictionary* _resourceDictionary;
    
    AudioController *_audioManager;
    
    GLuint _audioTextureID;
    GLubyte* _freqBuffer;
    GLubyte* _waveBuffer;
}

+ (ChannelResourceManager *)sharedInstance;

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
- (void)deferLoading;

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
- (NSData *)getResourceWithName:(NSURL *)name;
- (GLuint)getTextureWithName:(NSURL *)name;
- (GLKVector3)getTextureResolution:(NSURL *)name;
- (GLuint)getAudioTexture;
- (GLKVector3)getAudioTextureResolution;

@end
