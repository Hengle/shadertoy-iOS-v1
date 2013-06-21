//
//  TextureManager.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/21/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "TextureManager.h"

@implementation TextureManager

+ (TextureManager *)sharedInstance;
{
    static TextureManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      sharedInstance = [TextureManager new];
                  });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        pendingTextures = [NSMutableArray new];
        textureDictionary = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)addTexture:(NSURL *)path
{
    [pendingTextures addObject:path];
}

- (void)deferLoading
{
    @synchronized(self)
    {
        for (NSURL* path in pendingTextures)
        {
            if ([textureDictionary objectForKey:path.absoluteString] == nil)
            {
                NSError* error = nil;
                GLKTextureInfo* texture = [GLKTextureLoader textureWithContentsOfURL:path options:@{GLKTextureLoaderOriginBottomLeft: @YES} error:&error];
                
                if (error == nil)
                {
                    [self storeTexture:texture withName:path.absoluteString];
                
                    NSLog(@"Loaded texture %u for path %@", texture.name, path.absoluteString);
                }
                else
                {
                    NSLog(@"Error loading texture for path %@ - %@", path.absoluteString, error);
                }
            }
        }
        
        [pendingTextures removeAllObjects];
    }
}

- (void)storeTexture:(GLKTextureInfo *)texture withName:(NSString *)name
{
    [textureDictionary setObject:texture forKey:name];
}

- (GLuint)getTexture:(NSURL *)path
{
    GLKTextureInfo* info = [textureDictionary objectForKey:path.absoluteString];
    
    return info.name;
}

@end
