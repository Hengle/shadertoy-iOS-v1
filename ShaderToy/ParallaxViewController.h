//
//  ParallaxViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/1/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class ShaderInformationViewController;

@interface ParallaxViewController : UIViewController <GLKViewDelegate>

@property (strong, nonatomic) ShaderInformationViewController *informationViewController;

@end
