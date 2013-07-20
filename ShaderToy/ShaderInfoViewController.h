//
//  ShaderInfoViewController.h
//  Shadertoy
//
//  Created by skumancer on 7/14/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShaderInfo;

@interface ShaderInfoViewController : UIViewController
{
    ShaderInfo* _shaderInfo;
}

@property (strong, nonatomic) ShaderInfo* shaderInfo;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)share:(id)sender;
- (IBAction)like:(id)sender;

@end
