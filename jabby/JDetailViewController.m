//
//  JDetailViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//
// TODO
//* upload image


#import "JDetailViewController.h"

@interface JDetailViewController () <
    JSMessagesViewDelegate, JSMessagesViewDataSource, EGORefreshTableHeaderDelegate
>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic,strong) UIImage *willSendImage;


- (void)configureView;

@end



@implementation JDetailViewController

@synthesize table;
@synthesize messages;
@synthesize willSendImage;
@synthesize timestamps;
@synthesize info;
@synthesize navigationItem;


- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (NSString *)hisJidStr
{
    return [self.info valueForKey:@"jid"];
}

- (NSString *)hisName
{
    return [self.info valueForKey:@"name"];
}


-(void)configureInfo:(NSDictionary *)dict
{
    self.info = [NSDictionary dictionaryWithDictionary:dict];
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.messageInputView.textView.placeHolder = @"Say something!";
    
    self.sender = nil;
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:14.0f]];
    
    if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}
    [_refreshHeaderView refreshLastUpdatedDate];
    
    [self.navigationItem setLeftBarButtonItem:
     [PBFlatBarButtonItems backBarButtonItemWithTarget:self
                                              selector:@selector(showLeftMenu:)]];
}

- (void)viewDidLoad
{
    [self setDelegate:self];
    [self setDataSource:self];
    [super viewDidLoad];
    [self configureView];

    self.messages = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    [self reigsterNotificationObserver];
}

- (void)reigsterNotificationObserver
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didChatMessageIncoming:)
     name:@"Chat Message Incoming"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didChatMessageOutgoing:)
     name:@"Chat Message Outgoing"
     object:nil];
}

-(void)showLeftMenu:(UIBarButtonItem *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)didChatMessageIncoming:(NSNotification*)notification
{
    NSString *kind = [notification.userInfo valueForKey:@"kind"];
    JMessage *xmppMessage = notification.object;
    [self.messages addObject:[[JMessage alloc] initWithXMPPMessage:xmppMessage kind:kind]];
    [JSMessageSoundEffect playMessageReceivedSound];
    [self reloadToBottom:YES];
}
-(void)didChatMessageOutgoing:(NSNotification*)notification
{
    NSString *kind = [notification.userInfo valueForKey:@"kind"];
    JMessage *xmppMessage = notification.object;
    [self.messages addObject:[[JMessage alloc] initWithXMPPMessage:xmppMessage kind:kind]];
    [JSMessageSoundEffect playMessageReceivedSound];
    [self reloadToBottom:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setTitle:[self hisName]];
    [self setMessages:[[JIMCenter sharedInstance] fetchLatestMessage:[self hisJidStr]]];
    [[JIMCenter sharedInstance] activeSession:[self hisJidStr]];
    [self reloadToBottom:NO];
}

- (void)viewDidUnload
{
    [self.navigationItem setLeftBarButtonItem:nil];
    _refreshHeaderView=nil;
    [super viewDidUnload];
    
}

//#pragma mark - Split view
//
//- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
//{
//    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
//    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
//    self.masterPopoverController = popoverController;
//}
//
//- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
//{
//    // Called when the view is shown again in the split view, invalidating the button and popover controller.
//    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
//    self.masterPopoverController = nil;
//}

#pragma mark - JSMessagesViewDelegate

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    [[JIMCenter sharedInstance] sendMessage:text to:[self hisJidStr]];
    [self finishSend];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.messages objectAtIndex:indexPath.row] isOutgoing]) {
        return JSBubbleMessageTypeOutgoing;
    } else {
        return JSBubbleMessageTypeIncoming;
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[self getColorByMessageType:type]];
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
    }
}

#pragma mark - JSMessagesViewDataSource

- (id<JSMessageData>)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getMessage:indexPath];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    return nil;
}


#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

#pragma mark - EGORefreshTableHeaderView

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:0.5f];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return _reloading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date];
}



#pragma These are private methods.

-(JMessage *)getMessage:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.row];
}

- (void)reloadTableViewDataSource
{
	_reloading = YES;
    
    NSUInteger count = [self.messages count];
    NSUInteger page = count / 20 + 1;
    NSMutableArray *moreMessages = [[JIMCenter sharedInstance] fetchMuchMoreMessage:[self hisJidStr] page:page];
    [moreMessages addObjectsFromArray:self.messages];
    self.messages = [NSMutableArray arrayWithArray:moreMessages];
}

- (void)doneLoadingTableViewData{
	_reloading = NO;
    
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
}

- (void)reloadToBottom:(BOOL)animate
{
    [self.tableView reloadData];
    [self scrollToBottomAnimated:animate];
}

- (UIColor *)getColorByMessageType:(JSBubbleMessageType)type
{
    if (type == JSBubbleMessageTypeOutgoing) {
        return [UIColor turquoiseColor];
    } else {
        return [UIColor cloudsColor];
    }
}


@end
