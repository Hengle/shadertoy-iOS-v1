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
#import "Reachability.h"

@interface ShaderRequest ()
{
    Reachability* _reachability;
}

- (void)resetState;

- (void)doneWithRequest;
- (NSString *)categoryStringForCategory:(EShaderCategory)category;

- (BOOL)verifyConnection;
- (void)checkNetworkStatus:(NSNotification *)notice;

@end

@implementation ShaderRequest

- (id)init
{
    if ((self = [super init]))
    {
        [self resetState];
        
        _reachability = [Reachability reachabilityForInternetConnection];//reachabilityWithHostName:@"https://www.shadertoy.com/"];
        [_reachability startNotifier];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        
        [ShaderManager sharedInstance].delegate = self;
    }
    
    return self;
}

- (void)resetState
{
    _currentIndex = 0;
    _currentCategory = Newest;
    _activeRequest = false;
    _pendingRequest = false;
}

- (void)requestCategory:(EShaderCategory)category
{
    NSLog(@"[ShaderRequest] Changing category to %lu", (unsigned long)category);
    
    // Reset the state
    [self resetState];
    
    // Set the new category
    _currentCategory = category;
    
    // Verify we have a connection or queue the request
    if ([self verifyConnection])
    {
        [self requestNewShaders];
    }
    else
    {
        _pendingRequest = true;
    }
}

- (void)requestNewShaders
{
    if (!_activeRequest)
    {
        // Check for connection, if there is, just go on with our request
        // otherwise set a pending request and stop until we have connection
        if ([self verifyConnection])
        {
            // We have a valid request, set it to active
            _activeRequest = true;
            
            // Clear the pending request, we know we have a valid request going on
            _pendingRequest = false;
            
            // Show the notification UI for that we are Loading Shaders
            [SVProgressHUD showWithStatus:@"Loading Shaders" maskType:SVProgressHUDMaskTypeClear];
            
            // Dispatch the Request on a background thread to free up the Main Thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                               static NSString* apiKey = @"Nt8twr";
                               NSString* s = [NSString stringWithFormat:@"sort=%@&from=%d&num=12&key=%@", [self categoryStringForCategory:_currentCategory], _currentIndex, apiKey];
                               NSString* urlString = [NSString stringWithFormat:@"https://www.shadertoy.com/api/v1/shaders?%@", s];
                               NSLog(@"[ShaderRequest] Asking for shaders with URL %@", urlString);

                               NSData* shaderListData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
                               _newShaders = [NSMutableArray new];
                               
                               if (shaderListData != nil)
                               {
                                   NSError* listError = nil;
                                   NSDictionary* response = [NSJSONSerialization JSONObjectWithData:shaderListData options:kNilOptions error:&listError];
                                   
                                   if (listError == nil)
                                   {
                                       NSLog(@"[ShaderRequest] Processing shader info...");
                                       
                                       NSNumber* results = response[@"Shaders"];
                                       if (results.intValue > 0)
                                       {
                                           for (NSString* shaderID in response[@"Results"])
                                           {
                                               NSString* shaderDetailsRequest = [NSString stringWithFormat:@"https://www.shadertoy.com/api/v1/shaders/%@?key=%@", shaderID, apiKey];
                                               NSData* shaderDetailsData = [NSData dataWithContentsOfURL:[NSURL URLWithString:shaderDetailsRequest]];
                                               
                                               if (shaderDetailsData != nil)
                                               {
                                                   NSError* detailError = nil;
                                                   NSDictionary* shaderDetails = [NSJSONSerialization JSONObjectWithData:shaderDetailsData options:kNilOptions error:&detailError];
                                                   
                                                   if (detailError == nil)
                                                   {
                                                       NSDictionary* details = shaderDetails[@"Shader"];
                                                       ShaderInfo* shader = [[ShaderInfo alloc] initWithJSONDictionary:details];
                                                       
                                                       [_newShaders addObject:shader];
                                                   }
                                                   else
                                                   {
                                                       NSLog(@"[ShaderRequest] Error loading shader details %@", detailError.localizedDescription);
                                                   }
                                               }
                                               else
                                               {
                                                   NSLog(@"[ShaderRequest] Error loading shader details for %@", shaderID);
                                               }
                                           }
                                       }
                                       
                                       // If there are shaders to compile, do it, otherwise the request is invalidated
                                       if (_newShaders.count > 0)
                                       {
                                           NSLog(@"[ShaderRequest] Compiling %lu shaders...", (unsigned long)_newShaders.count);
                                           [[ShaderManager sharedInstance] addShaders:_newShaders];
                                       }
                                   }
                                   else
                                   {
                                       NSLog(@"[ShaderRequest] Error loading shader list %@", listError.localizedDescription);
                                   }
                               }
                           });
        }
        else
        {
            _pendingRequest = true;
        }
    }
}

- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager shaders:(NSArray *)shaders
{
    NSLog(@"[ShaderRequest] Request done, added %lu shaders!", (unsigned long)shaders.count);
    
    // Deactivate the current request
    _activeRequest = false;
    
    // Increase the shader index by the amount of shaders returned
    _currentIndex += shaders.count;
    
    // Dispatch the delegate and dismiss the loading UI on the Main Thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [self.delegate shaderRequest:self hasShadersReady:shaders];
    });
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

- (BOOL)verifyConnection
{
    // Verify connection, otherwise show the UI Notification
    NetworkStatus status = [_reachability currentReachabilityStatus];
    if (status == NotReachable)
    {
        [SVProgressHUD showErrorWithStatus:@"No Internet Connection"];
        return false;
    }
    
    return true;
}

- (void)checkNetworkStatus:(NSNotification *)notice
{
    // When status changes, verify our connection and
    // start a request, if necessary
    if ([self verifyConnection] && _pendingRequest)
    {
        [self requestNewShaders];
    }
}

@end
