//
//  ShaderMenuViewController.m
//  Shadertoy
//
//  Created by Ricardo Chavarria on 5/4/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderMenuViewController.h"
#import "ShaderMenuCell.h"

@interface ShaderMenuViewController ()

- (void)setIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected;
- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected;

@end

@implementation ShaderMenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    
    _previousIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void)setIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UIImageView* imageView = (UIImageView *)[cell viewWithTag:100];
    UILabel* textLabel = (UILabel *)[cell viewWithTag:101];
    
    if (selected)
    {
        textLabel.textColor = [UIColor colorWithRed:0 green:0.6823 blue:1.0 alpha:1.0];
    }
    else
    {
        textLabel.textColor = [UIColor lightGrayColor];
    }
    
    imageView.image = [self imageForIndexPath:indexPath selected:selected];
}

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    UIImage *image = nil;
    
    switch (indexPath.row)
    {
        case 0:
            image = [UIImage imageNamed:(selected ? @"time_selected.png" : @"time.png")];
            break;
            
        case 1:
            image = [UIImage imageNamed:(selected ? @"fire_selected.png" : @"fire.png")];
            break;
            
        case 2:
            image = [UIImage imageNamed:(selected ? @"love_hollow_selected.png" : @"love_hollow.png")];
            break;
            
        case 4:
            image = [UIImage imageNamed:@"logo-text.png"];
            break;
    }
    
    return image;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int cells = 0;
    
    // Return the number of rows in the section.
    switch (section)
    {
        case 0:
            cells = 5;
            break;
            
        case 1:
            cells = 0;
            break;
    }
    
    return cells;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    UIImageView* imageView = nil;
    UILabel* textLabel = nil;
    
    if (indexPath.section == 0)
    {
        switch (indexPath.row)
        {
            case 0:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuBasicCell" forIndexPath:indexPath];
                cell.userInteractionEnabled = TRUE;
                imageView = (UIImageView *)[cell viewWithTag:100];
                textLabel = (UILabel *)[cell viewWithTag:101];
                
                imageView.image = [self imageForIndexPath:indexPath selected:TRUE];
                
                textLabel.text = @"Newest";
                textLabel.textColor = [UIColor colorWithRed:0 green:0.6823 blue:1.0 alpha:1.0];
                
                break;
                
            case 1:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuBasicCell" forIndexPath:indexPath];
                cell.userInteractionEnabled = TRUE;
                imageView = (UIImageView *)[cell viewWithTag:100];
                textLabel = (UILabel *)[cell viewWithTag:101];
                
                imageView.image = [self imageForIndexPath:indexPath selected:FALSE];
                textLabel.text = @"Popular";
                
                break;
                
            case 2:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuBasicCell" forIndexPath:indexPath];
                cell.userInteractionEnabled = TRUE;
                imageView = (UIImageView *)[cell viewWithTag:100];
                textLabel = (UILabel *)[cell viewWithTag:101];
                
                imageView.image = [self imageForIndexPath:indexPath selected:FALSE];
                textLabel.text = @"Loved";
                
                break;
                
            case 3:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuBasicCell" forIndexPath:indexPath];
                cell.userInteractionEnabled = FALSE;
                textLabel = (UILabel *)[cell viewWithTag:101];
                
                textLabel.text = @"";
                
                break;
                
            case 4:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MenuImageCell" forIndexPath:indexPath];
                cell.userInteractionEnabled = FALSE;
                imageView = (UIImageView *)[cell viewWithTag:100];
                
                imageView.image = [self imageForIndexPath:indexPath selected:FALSE];
                
                break;
                
            default:
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row < 3)
    {
        NSString *category = nil;

        switch (indexPath.row)
        {
            case 0:
                category = @"newest";
                break;
                
            case 1:
                category = @"popular";
                break;
                
            case 2:
                category = @"love";
                break;
        }
        
        [self setIndexPath:_previousIndexPath selected:FALSE];
        [self setIndexPath:indexPath selected:TRUE];
        
        _previousIndexPath = indexPath;
        
        [self.delegate shaderMenu:self choseShaderCategory:category];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.revealViewController revealToggleAnimated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row < 3) ? indexPath : nil;
}

@end
