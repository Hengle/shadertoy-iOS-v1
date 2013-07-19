//
//  ShaderMenuViewController.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/4/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShaderMenuViewController;

@protocol ShaderMenuDelegate <NSObject>

- (void)shaderMenu:(ShaderMenuViewController *)shaderMenu choseShaderCategory:(NSString *)category;

@end

@interface ShaderMenuViewController : UITableViewController
{
    NSIndexPath* _previousIndexPath;
}

@property (nonatomic, assign) id<ShaderMenuDelegate> delegate;

@end
