//
//  JMasterViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JMasterViewController.h"

#import "JDetailViewController.h"

#import "JLoginViewController.h"

@interface JMasterViewController ()

@end


@implementation JMasterViewController

@synthesize friendList = _friendList;

- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    


    self.title = @"Friends";
    self.detailViewController = (JDetailViewController *)[
        [self.splitViewController.viewControllers lastObject] topViewController];
    
    NSMutableArray *onlineFriends = [NSMutableArray array];
    NSMutableArray *offlineFriends = [NSMutableArray array];
    self.friendList = [NSMutableArray arrayWithObjects:onlineFriends,offlineFriends, nil];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
}

- (void)viewDidAppear:(BOOL)animated {
    JAppDelegate *appDelegate = [self appDelegate];
    appDelegate.imCenter.friendListDelegate = self;
    appDelegate.imCenter.messageDelegate = self;
    
    [self reloadFriendList];
    
    if (![[self appDelegate] isConnected] &&
        ![[self appDelegate].imCenter.xmppStream isConnecting] &&
        [self missAccount]) {
        [self pushGoToLoginView];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)missAccount
{
    return ![[self appDelegate].imCenter.xmppStream isAuthenticated];
}

- (void)pushGoToLoginView
{
    
    [self performSegueWithIdentifier:@"GoToLogin" sender:self];
}

- (void)reloadFriendList
{
    self.friendList[0] = [self appDelegate].imCenter.onlineFriends;
    self.friendList[1] = [self appDelegate].imCenter.offlineFriends;
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.friendList[section] count];
}


- (PBFlatGroupedStyleCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    PBFlatGroupedStyleCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[PBFlatGroupedStyleCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    [cell setFirstCell:NO];
    [cell setLastCell:NO];
    
    if(indexPath.row == 0) {
        [cell setFirstCell:YES];
    } else if (indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell setLastCell:YES];
    }
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(PBFlatGroupedStyleCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *friend = (NSDictionary *)[self.friendList[indexPath.section] objectAtIndex:indexPath.row];
    NSString *jidStr = [friend valueForKey:@"jid"];
    // XMPPUserCoreDataStorageObject *user = [[self appDelegate].imCenter getUserObjectByJidStr:jidStr];
    NSData *avatar = [[self appDelegate].imCenter getAvatar:jidStr];
    cell.textLabel.text = [friend valueForKey:@"name"];
    PBFlatRoundedImageView *avatarView = [PBFlatRoundedImageView contactImageViewWithImage:[UIImage imageWithData:avatar]];
    [cell setIconImageView:avatarView];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 30.0f;
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *__view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 30.0f)];
    [__view setBackgroundColor:[UIColor clearColor]];
    return __view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    XMPPPresence *presence = (XMPPPresence *)[self.friendList objectAtIndex:indexPath.row];
//    self.detailViewController.detailItem = presence;
//    [self performSegueWithIdentifier:@"chat" sender:self];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView)
    {
        if (section == 0)
        {
            return @"Online";
        }
        else if (section == 1)
        {
            return @"Offline";
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"chat"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        NSDictionary *info = (NSDictionary *)[self.friendList[indexPath.section] objectAtIndex:indexPath.row];
        [[segue destinationViewController] configureInfo:info];
    }
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *friend = (NSDictionary *)[self.friendList[indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = [friend valueForKey:@"name"];
}


# pragma mark - JFriendListDelegate

- (void)needLogin {
    if ([self missAccount]) {
        FUIAlertView *alert = [[self appDelegate] alert:@"Authenticated Failed!" andTitle:@"Warning"];
        [alert setOnDismissAction:^{
            [self pushGoToLoginView];
        }];
    }
}

-(void)onAbsence:(XMPPPresence *)presence {
    [self reloadFriendList];
}

-(void)onPresence:(XMPPPresence *)presence
{
    [self reloadFriendList];
}

-(void)didSetup:(NSArray *)friends
{
    [self reloadFriendList];
}


#pragma mark - JMessageDelegate

-(void)onReceivedMessage:(XMPPMessage *)message from:(id)user
{
    if ([message isMessageWithBody]) {
        NSString *notificationBody = [NSString stringWithFormat:@"%@: %@",[user displayName],[message body]];
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [user jidStr],@"jid",[user displayName],@"name", nil];
        [[self appDelegate] sendNotification:notificationBody withUserInfo:info];
    }
}

#pragma mark - FUIAlertViewDelegate


@end
