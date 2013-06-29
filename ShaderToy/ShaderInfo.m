//
//  ShaderInfo.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 6/19/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderInfo.h"

@implementation ShaderParameters

- (id)init
{
    self = [super init];
    if (self)
    {
        _channelInfo = malloc(sizeof(GLuint) * 4);
        _channelTime = malloc(sizeof(float) * 4);
        
        for (int i = 0; i < 4; i++)
        {
            _channelInfo[i] = 0;
            _channelTime[i] = 0.0f;
        }
    }
    
    return self;
}

- (GLKVector4)date
{
    NSDate* date = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:date];
    
    return GLKVector4Make(components.year, components.month, components.day, (components.minute * 60) + components.second);
}

- (void)clearChannels
{
    for (int i = 0; i < 4; i++)
    {
        _channelInfo[i] = 0;
        _channelTime[i] = 0.0f;
    }
}

@end

@implementation ShaderInput

- (id)initWithJSONDictionary:(NSDictionary*)inputData
{
    self = [super init];
    if (self)
    {
        _ID = ((NSNumber*)inputData[@"id"]).integerValue;
        
        // If the file is available locally, use the local file
        // otherwise download it
        NSString* source = inputData[@"src"];
        _source = [[NSBundle mainBundle] URLForResource:source withExtension:nil];
        if (_source == nil)
        {
            _source = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.shadertoy.com%@", source]];
        }
        _type = inputData[@"ctype"];
        _channel = ((NSNumber*)inputData[@"channel"]).integerValue;
    }
    
    return self;
}

@end

@implementation ShaderOutput

- (id)initWithJSONDictionary:(NSDictionary*)outputData
{
    self = [super init];
    if (self)
    {
        _channel = outputData[@"channel"];
        _destination = outputData[@"dst"];
    }
    
    return self;
}

@end

@implementation ShaderRenderPass

- (id)initWithJSONDictionary:(NSDictionary*)renderpassData
{
    self = [super init];
    if (self)
    {
        // Parse inputs
        NSArray* inputs = renderpassData[@"inputs"];
        _inputs = [NSMutableArray new];
        for (NSDictionary* inputInfo in inputs)
        {
            ShaderInput* input = [[ShaderInput alloc] initWithJSONDictionary:inputInfo];
            [_inputs addObject:input];
        }
        
        // Parse outputs
        NSArray* outputs = renderpassData[@"outputs"];
        _outputs = [NSMutableArray new];
        for (NSDictionary* outputInfo in outputs)
        {
            ShaderOutput* output = [[ShaderOutput alloc] initWithJSONDictionary:outputInfo];
            [_outputs addObject:output];
        }
        
        _name = renderpassData[@"name"];
        _description = renderpassData[@"description"];
        _code = renderpassData[@"code"];
    }
    
    return self;
}

@end

@implementation ShaderInfo

- (id)initWithJSONDictionary:(NSDictionary*)json
{
    self = [super init];
    if (self)
    {
        _version = json[@"ver"];
        NSDictionary* info = json[@"info"];
        
        _ID = info[@"id"];
        _viewed = ((NSNumber*)info[@"viewed"]).integerValue;
        _name = info[@"name"];
        _username = info[@"username"];
        _description = info[@"description"];
        _likes = ((NSNumber*)info[@"likes"]).integerValue;
        _published = info[@"published"];
        
        _tags = info[@"tags"];
        _hasliked = info[@"hasliked"];
        
        // Parse render pass
        NSArray* renderpasses = json[@"renderpass"];
        _renderpasses = [NSMutableArray new];
        for (NSDictionary* renderpassData in renderpasses)
        {
            ShaderRenderPass* renderpass = [[ShaderRenderPass alloc] initWithJSONDictionary:renderpassData];
            [_renderpasses addObject:renderpass];
        }
    }
    
    return self;
}

@end
