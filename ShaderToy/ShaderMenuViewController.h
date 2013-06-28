//
//  ShaderMenuViewController.h
//  ShaderToy
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

@property (nonatomic, retain) id<ShaderMenuDelegate> delegate;

@end
