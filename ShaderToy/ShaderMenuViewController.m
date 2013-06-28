//
//  ShaderMenuViewController.m
//  ShaderToy
//
//  Created by Ricardo Chavarria on 5/4/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

#import "ShaderMenuViewController.h"
#import "ShaderMenuCell.h"

@interface ShaderMenuViewController ()

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.backgroundColor = [UIColor darkGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int cells = 0;
    
    // Return the number of rows in the section.
    switch (section)
    {
        case 0:
            cells = 3;
            break;
            
        case 1:
            cells = 0;
            break;
    }
    
    return cells;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* name = nil;
    switch (section)
    {
        case 0:
            name = @"Shaders";
            break;
            
        case 1:
            name = @"Favorites";
            break;
    }
    
    return name;
}

//- (UIView* )tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    KGNoiseView* view = [KGNoiseView new];
//    
//    return view;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ShaderMenuCell";
    ShaderMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0)
    {
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Newest";
                cell.imageView.image = [UIImage imageNamed:@"danger-8-icon"];
                break;
                
            case 1:
                cell.textLabel.text = @"Popular";
                cell.imageView.image = [UIImage imageNamed:@"dashboard-5-icon"];
                break;
                
            case 2:
                cell.textLabel.text = @"Loved";
                cell.imageView.image = [UIImage imageNamed:@"favorite-3-icon"];
                break;
                
            default:
                break;
        }
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
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
        
        [self.delegate shaderMenu:self choseShaderCategory:category];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.revealViewController revealToggleAnimated:YES];
}

@end
