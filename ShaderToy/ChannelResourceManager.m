//
//  TextureManager.m
//  ShaderToy
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

- (NSData *)loadDataFromURL:(NSURL *)path;

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
    }
    
    return self;
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
                    [self loadDataFromURL:info.path];
                }
            }
        }
        
        [_pendingResources removeAllObjects];
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
    }
    
    return resource;
}

- (NSData *)loadDataFromURL:(NSURL *)path
{
    NSData* resource = [NSData dataWithContentsOfURL:path];
    if (resource != nil)
    {
        [self storeResource:resource withName:path.absoluteString];
    }
    else
    {
        NSLog(@"Couldn't get resource for path %@", path.absoluteString);
    }
    
    return resource;
}

@end
