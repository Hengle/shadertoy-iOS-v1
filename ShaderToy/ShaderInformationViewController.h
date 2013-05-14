//
//  ShaderInformationViewController.h
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/13/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShaderInformation;

@interface ShaderInformationViewController : UIViewController

@property (strong, nonatomic) ShaderInformation *shaderInformation;
@property (strong, nonatomic) IBOutlet UILabel *shaderNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;

- (IBAction)share:(id)sender;
- (IBAction)like:(id)sender;

@end
