//
//  MenuViewController.h
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/4/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuViewController;

@protocol MenuDelegate <NSObject>

- (void)shaderMenu:(MenuViewController *)shaderMenu choseShaderCategory:(EShaderCategory)category;

@end

@interface MenuViewController : UITableViewController
{
    NSIndexPath* _previousIndexPath;
}

@property (nonatomic, assign) id<MenuDelegate> delegate;

@end
