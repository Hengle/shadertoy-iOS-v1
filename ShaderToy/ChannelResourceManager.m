//
//  TextureManager.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ChannelResourceManager.h"
#import "ShaderManager.h"

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
{
    // Multithreading support
    EAGLContext* _context;
    NSThread* _managerThread;
}

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
        
        _context = [[ShaderManager sharedInstance] createNewContext];
        
        _managerThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMainLoop) object:nil];
        [_managerThread start];

    }
    
    return self;
}

- (void)threadMainLoop
{
    NSLog(@"[ChannelResourceManager] Starting manager thread");
    @synchronized(_managerThread)
    {
        @autoreleasepool
        {
            while (true)
            {
                @synchronized(_context)
                {
                    // Set the context and framebuffer
                    [EAGLContext setCurrentContext:_context];
                    
                    // Initialize the controller
                    [self deferredLoading];
                    
                    glFlush();
                    
                    [EAGLContext setCurrentContext:nil];
                }
                
                [NSThread sleepForTimeInterval:1.0f];
            }
        }
    }
    
    NSLog(@"[ShadeChannelResourceManagerrManager] Finished running thread");
}

- (void)deferredLoading
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
}

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
{
    ResourceInfo* info = [[ResourceInfo alloc] initWithType:type andPath:path];
    [_pendingResources addObject:info];
}

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
{
    if ((name != nil) && (resource != nil) && [_resourceDictionary objectForKey:name] == nil)
    {
        [_resourceDictionary setObject:resource forKey:name];
    }
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
    GLuint textureID = 0;
    GLKTextureInfo* texture = [_resourceDictionary objectForKey:name.absoluteString];
    if (texture == nil)
    {
        texture = [self loadTextureFromURL:name];
        if (texture != nil)
        {
            [self storeResource:texture withName:name.absoluteString];
            textureID = texture.name;
        }
    }
    else
    {
        textureID = texture.name;
    }
    
    return textureID;
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

- (NSData *)loadDataFromURL:(NSURL *)path
{
    NSData* resource = [NSData dataWithContentsOfURL:path];
    if (resource == nil)
    {
        NSLog(@"[ChannelResourceManager] Couldn't load resource for path %@", path.absoluteString);
    }
    
    return resource;
}

- (GLKTextureInfo *)loadTextureFromURL:(NSURL *)path
{
    NSError* error = nil;
    GLKTextureInfo* info = [GLKTextureLoader textureWithContentsOfURL:path options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
    
    if (error != nil)
    {
        NSLog(@"[ChannelResourceManager] Couldn't load texture for path %@ - Error: %@", path.absoluteString, error.userInfo[GLKTextureLoaderErrorKey]);
    }
    
    return info;
}

@end
