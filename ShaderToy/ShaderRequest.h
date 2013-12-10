//
//  ShaderRequest.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 10/7/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ShaderManager.h"

@class ShaderRequest;

@protocol ShaderRequestDelegate <NSObject>

- (void)shaderRequest:(ShaderRequest *)request hasShadersReady:(NSArray *)shaderList;

@end

@interface ShaderRequest : NSObject <ShaderManagerDelegate>
{
    bool _pendingRequest;
    bool _activeRequest;
    int _currentIndex;
    EShaderCategory _currentCategory;
    NSMutableArray* _newShaders;
}

@property (nonatomic, retain) id<ShaderRequestDelegate> delegate;

- (void)requestCategory:(EShaderCategory)category;
- (void)requestNewShaders;

@end
