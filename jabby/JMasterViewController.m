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
#import "MMDrawerBarButtonItem.h"

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
    
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self reigsterNotificationObserver];
    
}

- (void)reigsterNotificationObserver
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didChatMessageIncomingOnFriendList:)
     name:@"Chat Message Incoming"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didPresenceOnFriendList:) name:@"Presence" object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didAbsenceOnFriendList:) name:@"Absence" object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didIQReceivedOnFriendList:) name:@"IQ Received" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [self reloadFriendList];

    UIBarButtonItem *leftDrawerButton = [PBFlatBarButtonItems menuBarButtonItemWithTarget:self
                                             selector:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
}

- (void)leftDrawerButtonPress:(UIBarButtonItem *)sender
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

-(MMDrawerController*)mm_drawerController{
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController != nil) {
        if([parentViewController isKindOfClass:[MMDrawerController class]]){
            return (MMDrawerController *)parentViewController;
        }
        parentViewController = parentViewController.parentViewController;
    }
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)reloadFriendList
{
    NSMutableArray *onlineFriends = [JIMCenter sharedInstance].onlineFriends;
    NSMutableArray *offlineFriends = [JIMCenter sharedInstance].offlineFriends;
    self.friendList = [NSMutableArray arrayWithObjects:onlineFriends,offlineFriends, nil];
    [[JIMCenter sharedInstance] cacheFriendList];
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.friendList[section] count];
}

- (void)configureCell:(PBFlatGroupedStyleCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *friend = (NSDictionary *)[self.friendList[indexPath.section] objectAtIndex:indexPath.row];
    NSString *jidStr = [friend valueForKey:@"jid"];
    [cell.textLabel setText:[friend valueForKey:@"name"]];
    [self configureCellIcon:cell forJid:jidStr];
}

- (void)configureCell:(PBFlatGroupedStyleCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // dummy
}

- (void)configureCellIcon:(PBFlatGroupedStyleCell *)cell forJid:(NSString *)jidStr
{
    UIImage *avatar = [[JIMCenter sharedInstance] getAvatarImage:jidStr];
    PBFlatRoundedImageView *avatarView = [PBFlatRoundedImageView contactImageViewWithImage:avatar];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Online";
    } else if (section == 1) {
        return @"Offline";
    }
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"chat"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        NSDictionary *info = (NSDictionary *)[self.friendList[indexPath.section] objectAtIndex:indexPath.row];
        [[segue destinationViewController] configureInfo:info];
    }
}

-(void)didAbsenceOnFriendList:(NSNotification *)notification
{
    [self reloadFriendList];
}

-(void)didPresenceOnFriendList:(NSNotification *)notification
{
    [self reloadFriendList];
}

-(void)didIQReceivedOnFriendList:(NSNotification *)notification
{
    [self reloadFriendList];
}

-(void)didChatMessageIncomingOnFriendList:(NSNotification *)notification
{
    XMPPMessage *message = notification.object;
    XMPPUserCoreDataStorageObject *user = [[JIMCenter sharedInstance] getUserObject:[message from]];
    NSString *notificationBody = [NSString stringWithFormat:@"%@: %@",[user displayName],[message body]];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [user jidStr],@"jid",[user displayName],@"name", nil];
    [[self appDelegate] sendNotification:notificationBody withUserInfo:info];
}

@end
