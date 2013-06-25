//
//  ShaderInfo.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/19/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

@interface ShaderParameters : NSObject

@property (nonatomic, assign) GLKVector3 resolution;
@property (nonatomic, assign) float time;
@property (nonatomic, assign) float *channelTime;
@property (nonatomic, assign) GLKVector4 mouseCoordinates;
@property (nonatomic, assign) GLuint *channelInfo;
@property (nonatomic, readonly) GLKVector4 date;
@property (nonatomic, readonly) int channelCount;

- (id)initWithChannelCount:(int)count;

@end

@interface ShaderInput : NSObject

@property (nonatomic, assign) int ID;
@property (readonly, nonatomic) NSURL* source;
@property (strong, nonatomic) NSString* type;
@property (nonatomic, assign) int channel;

- (id)initWithJSONDictionary:(NSDictionary*)inputData;

@end

@interface ShaderOutput : NSObject

@property (strong, nonatomic) NSString* channel;        // TODO : change this to an int when data is changed
@property (strong, nonatomic) NSString* destination;    // TODO : change this to an int when data is changed

- (id)initWithJSONDictionary:(NSDictionary*)outputData;

@end

@interface ShaderRenderPass : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* description;
@property (strong, nonatomic) NSMutableArray* inputs;
@property (strong, nonatomic) NSMutableArray* outputs;
@property (strong, nonatomic) NSString* code;

- (id)initWithJSONDictionary:(NSDictionary*)renderpassData;

@end

@interface ShaderInfo : NSObject

@property (strong, nonatomic) NSString* version;
@property (strong, nonatomic) NSString* ID;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* username;
@property (strong, nonatomic) NSString* description;
@property (strong, nonatomic) NSArray* tags;
@property (strong, nonatomic) NSMutableArray* renderpasses;
@property (nonatomic, assign) int likes;
@property (nonatomic, assign) bool published;
@property (nonatomic, assign) int viewed;
@property (nonatomic, assign) bool hasliked;

- (id)initWithJSONDictionary:(NSDictionary*)json;

@end
