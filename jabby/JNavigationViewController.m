//
//  JNavigationViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-22.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JNavigationViewController.h"
#import "JAppDelegate.h"
#import "JMasterViewController.h"
#import "JDetailViewController.h"

@interface JNavigationViewController ()

@end

@implementation JNavigationViewController

- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationBar configureFlatNavigationBarWithColor:[UIColor midnightBlueColor]];
    [self.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], NSForegroundColorAttributeName,
      [UIFont fontWithName:@"ArialMT" size:20.0], NSFontAttributeName,nil]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.view setBackgroundColor:[UIColor midnightBlueColor]];
    [self.tableView setBackgroundColor:[UIColor midnightBlueColor]];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma  mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[JIMCenter sharedInstance].sessions count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"CurrentChattingCell";
    
    NSString *jidStr = [[JIMCenter sharedInstance].sessions objectAtIndex:indexPath.row];
    UIImage *avatar = [[JIMCenter sharedInstance] getAvatarImage:jidStr];
    PBFlatRoundedImageView *avatarView = [PBFlatRoundedImageView contactImageViewWithImage:avatar];
    [avatarView setFrame:CGRectMake(17, 4, 36, 36)]; // (70 - 44) / 2
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    [cell setBackgroundColor:[UIColor midnightBlueColor]];
    [cell.contentView insertSubview:avatarView atIndex:0];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [[self appDelegate].drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {
        UINavigationController *controller = [self appDelegate].navigationController;
        if ([controller.topViewController isMemberOfClass:[JMasterViewController class]]) {
            [controller.topViewController performSegueWithIdentifier:@"chat" sender:self];
        } else if ([controller.topViewController isMemberOfClass:[JDetailViewController class]]) {
            JDetailViewController *detail = (JDetailViewController *)controller.topViewController;
            [detail configureInfo:[self chatTo]];
            [detail viewDidAppear:YES];
        }
    }];
}

- (NSDictionary *)chatTo
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *jidStr = [[JIMCenter sharedInstance].sessions objectAtIndex:indexPath.row];
    NSString *name = [[JIMCenter sharedInstance] getDisplayName:jidStr];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:jidStr,@"jid",name,@"name", nil];
    return info;
}
- (IBAction)didLogoutButtonTouchDown:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"UID"];
    [defaults removeObjectForKey:@"PASS"];
    [defaults synchronize];
    [[JIMCenter sharedInstance] disconnect];
    [[JIMCenter sharedInstance].xmppReconnect stop];
    [[self appDelegate].navigationController performSegueWithIdentifier:@"NavGoToLogin" sender:self];
}

@end
