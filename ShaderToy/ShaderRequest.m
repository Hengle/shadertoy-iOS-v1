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
    NSLog(@"ShaderRequest: Changing cateogory to %d", category);
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

- (NSString*)encodeString:(NSString *)s
{
    int len = [s length];
    
    NSString* dic = @"cDfN3WX4dms7twlM";
    NSString* res = @"";
    
    int r = 3876781;
    for( int i=0; i < len; i++ )
    {
        // random number
        r = (r * 0x343fd + 0x269ec3) & 0xffffffff;
        int n = (r >> 20) & 0xff;
        
        // xor with random number
        int asciicode = [s characterAtIndex:i];
        int c = asciicode ^ n;
        
        // base256 to base16
        res = [NSString stringWithFormat:@"%@%c%c", res, [dic characterAtIndex:(c>>4)&0xf], [dic characterAtIndex:c&0xf]];
    }
    return res;
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                           ^{
                               NSString* hardwareString = [[UIDevice currentDevice].hardwareSimpleDescription stringByReplacingOccurrencesOfString:@" " withString:@""];
                               [hardwareString stringByReplacingOccurrencesOfString:@"(" withString:@""];
                               [hardwareString stringByReplacingOccurrencesOfString:@")" withString:@""];
                               
                               //
                               // Begin enconding
                               //
                               
                               NSInteger Seconds = ([[NSDate date] timeIntervalSince1970] + [[NSTimeZone defaultTimeZone] secondsFromGMT]);
                               
                               NSString* s = [NSString stringWithFormat:@"sort=%@&from=%d&num=12&device=%@&time=%d", [self categoryStringForCategory:_currentCategory], _currentIndex, hardwareString, Seconds];
                               NSString* res = [self encodeString:s];
                               
                               NSString* urlString = [NSString stringWithFormat:@"https://www.shadertoy.com/mobile/%@", res];
                               NSLog(@"ShaderRequest: Asking for shaders with URL %@", urlString);

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
                                           NSInteger Seconds2 = ([[NSDate date] timeIntervalSince1970] + [[NSTimeZone defaultTimeZone] secondsFromGMT]);
                                           NSString * res2 = [self encodeString:[NSString stringWithFormat:@"s=%@time=%d",shaderID, Seconds2]];
                                           
                                           NSData* shaderDetailsData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.shadertoy.com/mobile/%@", res2]]];
                                           
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
                                                   NSLog(@"ShaderRequest: Error loading shader details %@", detailError.localizedDescription);
                                               }
                                           }
                                           else
                                           {
                                               NSLog(@"ShaderRequest: Error loading shader details for %@", shaderID);
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
                                           [self doneWithRequest];
                                       }
                                   }
                                   else
                                   {
                                       NSLog(@"Error loading shader list %@", listError.localizedDescription);
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

- (void)shaderManagerDidFinishCompiling:(ShaderManager *)manager
{
    [self doneWithRequest];
}

- (void)doneWithRequest
{
    NSLog(@"ShaderRequest: Request done, %d shaders!", _newShaders.count);
    
    // Deactivate the current request
    _activeRequest = false;
    
    // Increase the shader index by the amount of shaders returned
    _currentIndex += _newShaders.count;
    
    // Dispatch the delegate and dismiss the loading UI on the Main Thread
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [SVProgressHUD dismiss];
                       [self.delegate shaderRequest:self hasShadersReady:_newShaders];
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
