//
//  ShaderRequest.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 10/7/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderRequest.h"
#import "ShaderInfo.h"
#import "ShaderManager.h"

@interface ShaderRequest ()

- (NSString *)categoryStringForCategory:(EShaderCategory)category;

@end

@implementation ShaderRequest

- (id)init
{
    if ((self = [super init]))
    {
        _currentIndex = 0;
        _currentCategory = Newest;
        
        [ShaderManager sharedInstance].delegate = self;
    }
    
    return self;
}

- (void)requestCategory:(EShaderCategory)category
{
    _currentIndex = 0;
    _currentCategory = category;
    _activeRequest = false;
    
    [self requestNewShaders];
}

- (void)requestNewShaders
{
    if (!_activeRequest)
    {
        _activeRequest = true;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           NSString* urlString = [NSString stringWithFormat:@"https://www.shadertoy.com/mobile.htm?sort=%@&from=%d&num=12", [self categoryStringForCategory:_currentCategory], _currentIndex];
                           
                           NSData* shaderListData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
                           _newShaders = [NSMutableArray new];
                           
                           if (shaderListData != nil)
                           {
                               NSError* listError = nil;
                               NSArray* shaderList = [NSJSONSerialization JSONObjectWithData:shaderListData options:kNilOptions error:&listError];
                               
                               if (listError == nil)
                               {
                                   for (NSString* shaderID in shaderList)
                                   {
                                       NSData* shaderDetailsData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.shadertoy.com/mobile.htm?s=%@", shaderID]]];
                                       
                                       if (shaderDetailsData != nil)
                                       {
                                           NSError* detailError = nil;
                                           NSArray* shaderDetails = [NSJSONSerialization JSONObjectWithData:shaderDetailsData options:kNilOptions error:&detailError];
                                           
                                           if (detailError == nil)
                                           {
                                               ShaderInfo* shader = [[ShaderInfo alloc] initWithJSONDictionary:shaderDetails[0]];
                                               
                                               [_newShaders addObject:shader];
                                           }
                                           else
                                           {
                                               NSLog(@"Error loading shader details %@", detailError.localizedDescription);
                                           }
                                       }
                                       else
                                       {
                                           NSLog(@"Error loading shader details for %@", shaderID);
                                       }
                                   }
                                   
                                   // Figure out which shaders need to be compiled and create a new list to send to the shader manager
                                   NSMutableArray* shadersToCompile = [NSMutableArray new];
                                   for (ShaderInfo* shader in _newShaders)
                                   {
                                       // Check that the shader does not exist
                                       if (![[ShaderManager sharedInstance] shaderExists:shader])
                                       {
                                           [shadersToCompile addObject:shader];
                                       }
                                   }
                                   
                                   // If there are shaders to compile, do it, otherwise the request is invalidated
                                   if (shadersToCompile.count > 0)
                                   {
                                       [[ShaderManager sharedInstance] addShaders:shadersToCompile];
                                   }
                                   else
                                   {
                                       [self.delegate shaderRequest:self hasShadersReady:_newShaders];
                                       _activeRequest = false;
                                   }
                               }
                               else
                               {
                                   NSLog(@"Error loading shader list %@", listError.localizedDescription);
                               }
                           }
                       });
        
        _currentIndex += 12;
    }
}

- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager
{
    [self.delegate shaderRequest:self hasShadersReady:_newShaders];
    _activeRequest = false;
}

- (NSString *)categoryStringForCategory:(EShaderCategory)category
{
    NSString* categoryString = nil;
    
    switch (category)
    {
        case Newest:
            categoryString = @"newest";
            break;
            
        case Popular:
            categoryString = @"popular";
            break;
            
        case Love:
            categoryString = @"love";
            break;
            
        default:
            break;
    }
    
    return categoryString;
}

@end
