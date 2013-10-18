//
//  TextureManager.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ChannelResourceManager.hpp"
#import "ShaderManager.hpp"

@interface ResourceInfo : NSObject

@property (nonatomic, retain) NSString* type;
@property (nonatomic, retain) NSURL * path;

- (id)initWithType:(NSString *)type andPath:(NSURL *)url;

@end

@implementation ResourceInfo

- (id)initWithType:(NSString *)type andPath:(NSURL *)path
{
    self = [super init];
    
    if (self)
    {
        _type = type;
        _path = path;
    }
    
    return self;
}

@end

@interface ChannelResourceManager ()

- (NSData *)loadDataFromURL:(NSURL *)path;
- (GLKTextureInfo *)loadTextureFromURL:(NSURL *)path;

@end

@implementation ChannelResourceManager

+ (ChannelResourceManager *)sharedInstance;
{
    static ChannelResourceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      sharedInstance = [ChannelResourceManager new];
                  });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _pendingResources = [NSMutableArray new];
        _resourceDictionary = [NSMutableDictionary new];
        
        // Initialize Audio
        _audioManager = [AudioController sharedAudioManager];
        _audioManager.delegate = self;
        
        _audioTextureID = 0;
        _freqBuffer = (GLubyte *)malloc(sizeof(GLubyte) * 512);
        _waveBuffer = (GLubyte *)malloc(sizeof(GLubyte) * 512);
    }
    
    return self;
}

- (void)dealloc
{
    free(_freqBuffer);
    free(_waveBuffer);
}

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
{
    ResourceInfo* info = [[ResourceInfo alloc] initWithType:type andPath:path];
    [_pendingResources addObject:info];
}

- (void)deferLoading
{
    @synchronized(self)
    {
        for (ResourceInfo* info in _pendingResources)
        {
            if ([_resourceDictionary objectForKey:info.path.absoluteString] == nil)
            {
                if ([info.type isEqualToString:@"texture"] || [info.type isEqualToString:@"cubemap"])
                {
                    GLKTextureInfo* resource = [self loadTextureFromURL:info.path];
                    [self storeResource:resource withName:info.path.absoluteString];
                }
                else
                {
                    NSData* resource = [self loadDataFromURL:info.path];
                    [self storeResource:resource withName:info.path.absoluteString];
                }
            }
        }
        
        [_pendingResources removeAllObjects];
        
        if (_audioTextureID == 0)
        {
            glGenTextures(1, &_audioTextureID);
            glBindTexture(GL_TEXTURE_2D, _audioTextureID);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 512, 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, NULL);
            
            glBindTexture(GL_TEXTURE_2D, NULL);
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, _audioTextureID);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 512, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, _freqBuffer);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 1, 512, 1, GL_LUMINANCE, GL_UNSIGNED_BYTE, _waveBuffer);
        }
    }
}

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
{
    [_resourceDictionary setObject:resource forKey:name];
}

- (NSData *)getResourceWithName:(NSURL *)name
{
    NSData* resource = [_resourceDictionary objectForKey:name.absoluteString];
    if (resource == nil)
    {
        resource = [self loadDataFromURL:name];
        [self storeResource:resource withName:name.absoluteString];
    }
    
    return resource;
}

- (GLuint)getTextureWithName:(NSURL *)name
{
    GLKTextureInfo* texture = [_resourceDictionary objectForKey:name.absoluteString];
    if (texture == nil)
    {
        texture = [self loadTextureFromURL:name];
        [self storeResource:texture withName:name.absoluteString];
    }
    
    return texture.name;
}

- (GLKVector3)getTextureResolution:(NSURL *)name
{
    GLKTextureInfo* texture = [_resourceDictionary objectForKey:name.absoluteString];
    if (texture == nil)
    {
        texture = [self loadTextureFromURL:name];
        [self storeResource:texture withName:name.absoluteString];
    }
    
    return GLKVector3Make(texture.width, texture.height, 1.0);
}

- (GLuint)getAudioTexture
{
    return _audioTextureID;
}

- (GLKVector3)getAudioTextureResolution
{
    return GLKVector3Make(512.0, 2.0, 1.0);
}

- (NSData *)loadDataFromURL:(NSURL *)path
{
    NSData* resource = [NSData dataWithContentsOfURL:path];
    if (resource == nil)
    {
        NSLog(@"Couldn't load resource for path %@", path.absoluteString);
    }
    
    return resource;
}

- (GLKTextureInfo *)loadTextureFromURL:(NSURL *)path
{
    NSError* error = nil;
    GLKTextureInfo* info = [GLKTextureLoader textureWithContentsOfURL:path options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
    
    if (error != nil)
    {
        NSLog(@"Couldn't load texture for path %@", path.absoluteString);
    }
    
    return info;
}


#pragma mark - Audio stuff

- (void) receivedWaveSamples:(SInt32 *)samples length:(int)len
{
    int average = 0;
    for (int i = 0 ; i < len/2; i++)
    {
        _waveBuffer[i] = samples[i];
        average += samples[i];
    }
    //NSLog(@"Wave %d", average / len);
}

- (void) receivedFreqSamples:(int32_t *)samples length:(int)len;
{
    int average = 0;
    for (int i = 0 ; i < len; i++)
    {
        _freqBuffer[i] = samples[i];
        average += samples[i];
    }
    NSLog(@"FFT %d", average / len);
}

@end
