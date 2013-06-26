//
//  TextureManager.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ChannelResourceManager.h"

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
        pendingResources = [NSMutableArray new];
        resourceDictionary = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)addResource:(NSURL *)path ofType:(NSString *)type;
{
    ResourceInfo* info = [[ResourceInfo alloc] initWithType:type andPath:path];
    [pendingResources addObject:info];
}

- (void)deferLoading
{
    @synchronized(self)
    {
        for (ResourceInfo* info in pendingResources)
        {
            if ([resourceDictionary objectForKey:info.path.absoluteString] == nil)
            {
                if ([info.type isEqualToString:@"texture"] || [info.type isEqualToString:@"cubemap"])
                {
                    NSError* error = nil;
                    GLKTextureInfo* texture = [GLKTextureLoader textureWithContentsOfURL:info.path options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
                    
                    if (error == nil)
                    {
                        [self storeResource:texture withName:info.path.absoluteString];
                    
                        NSLog(@"Loaded texture %u for path %@", texture.name, info.path.absoluteString);
                    }
                    else
                    {
                        NSLog(@"Error loading texture for path %@ - %@", info.path.absoluteString, error);
                    }
                }
            }
        }
        
        [pendingResources removeAllObjects];
    }
}

- (void)storeResource:(NSObject *)resource withName:(NSString *)name;
{
    [resourceDictionary setObject:resource forKey:name];
}

- (GLuint)getResourceWithName:(NSURL *)name
{
    GLKTextureInfo* info = [resourceDictionary objectForKey:name.absoluteString];
    
    return info.name;
}

@end
