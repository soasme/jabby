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

}

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    [self configureView];
    
    //[[JSBubbleView appearance] setFont:/* your font for the message bubbles */];
    
    self.messageInputView.textView.placeHolder = @"Say something!";
    self.sender = nil;
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:14.0f]];
    
    
	if (_refreshHeaderView == nil) {
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}
    [_refreshHeaderView refreshLastUpdatedDate];
    
    self.messages = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    [self.navigationItem setLeftBarButtonItem:
     [PBFlatBarButtonItems backBarButtonItemWithTarget:self
                                              selector:@selector(showLeftMenu:)]];
    
    
    [self reigsterNotificationObserver];
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
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
    [self reloadToBottom];
}
-(void)didChatMessageOutgoing:(NSNotification*)notification
{
    NSString *kind = [notification.userInfo valueForKey:@"kind"];
    JMessage *xmppMessage = notification.object;
    [self.messages addObject:[[JMessage alloc] initWithXMPPMessage:xmppMessage kind:kind]];
    [JSMessageSoundEffect playMessageReceivedSound];
    [self reloadToBottom];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.title = [self hisName];
    JIMCenter *imCenter = [JIMCenter sharedInstance];
    self.messages = [imCenter fetchLatestMessage:[self hisJidStr]];
    NSLog(@"active hisJidStr:%@", [self hisJidStr]);
    [imCenter activeSession:[self hisJidStr]];
    [self reloadToBottom];
}

- (void)viewDidUnload
{
    [self.navigationItem setLeftBarButtonItem:nil];
    _refreshHeaderView=nil;
    [super viewDidUnload];
    
}

- (void)reloadToBottom
{
    [self.tableView reloadData];
    [self scrollToBottomAnimated:NO];
}

- (UIColor *)getColorByMessageType:(JSBubbleMessageType)type
{
    if (type == JSBubbleMessageTypeOutgoing) {
        return [UIColor turquoiseColor];
    } else {
        return [UIColor cloudsColor];
    }
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

/**
 *  Asks the delegate for the bubble image view for the row at the specified index path with the specified type.
 *
 *  @param type      The type of message for the row located at indexPath.
 *  @param indexPath The index path of the row to be displayed.
 *
 *  @return A `UIImageView` with both `image` and `highlightedImage` properties set.
 *  @see JSBubbleImageViewFactory.
 */
- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[self getColorByMessageType:type]];
}

/**
 *  Asks the delegate for the input view style.
 *
 *  @return A constant describing the input view style.
 *  @see JSMessageInputViewStyle.
 */
- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
        
        // Customize any UITextView properties
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
    return self.messages.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark UIScrollViewDelegate Methods
#pragma mark UIScrollViewDelegate Methods

// http://stackoverflow.com/questions/18778691/crash-on-exc-breakpoint-scroll-view
//- (void)dealloc {
//    [self.tableView setDelegate:nil];
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

#pragma mark - EGORefreshTableHeaderView

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:1.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}



#pragma These are private methods.

-(JMessage *)getMessage:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.row];
}

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
    
    NSUInteger count = [self.messages count];
    NSUInteger page = count / 20 + 1;
    NSMutableArray *moreMessages = [[JIMCenter sharedInstance] fetchMuchMoreMessage:[self hisJidStr] page:page];
    [moreMessages addObjectsFromArray:self.messages];
    self.messages = [NSMutableArray arrayWithArray:moreMessages];
    
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self.tableView reloadData];
//    [self.tableView setContentInset:UIEdgeInsetsMake(31.0f, 0.0f, 0.0f, 0.0f)];
	
}


@end
