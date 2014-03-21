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
    JSMessagesViewDelegate, JSMessagesViewDataSource
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
    self.title = [self hisName];
    self.messageInputView.textView.placeHolder = @"Say something!";
    self.sender = @"soasme";
    
    self.messages = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    [self.navigationItem setLeftBarButtonItem:
        [PBFlatBarButtonItems backBarButtonItemWithTarget:self
                              selector:@selector(showLeftMenu:)]];
    
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
    self.messages = [[JIMCenter sharedInstance] fetchLatestMessage:[self hisJidStr]];
    [JSMessageSoundEffect playMessageReceivedSound];
    [self reloadToBottom];
}
-(void)didChatMessageOutgoing:(NSNotification*)notification
{
    NSLog(@"chat mesage outgoing: %@", notification.userInfo);
    self.messages = [[JIMCenter sharedInstance] fetchLatestMessage:[self hisJidStr]];
    [JSMessageSoundEffect playMessageReceivedSound];
    [self reloadToBottom];
}

- (void)viewDidAppear:(BOOL)animated
{
    JIMCenter *imCenter = [JIMCenter sharedInstance];
    self.messages = [imCenter fetchLatestMessage:[self hisJidStr]];
    [self reloadToBottom];
}

- (void)viewDidUnload
{
    [self setView:nil];
    [super viewDidUnload];
}


- (void)reloadToBottom
{
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
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

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    NSLog(@"did send text.");
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
    return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor turquoiseColor]];
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

#pragma mark - JSMessagesViewDataSource

- (id<JSMessageData>)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *messageCoreData = [self getMessage:indexPath];
    JMessage *message = [[JMessage alloc] init];
    [message setText:[messageCoreData body]];

    return message;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
//    NSString *jidStr = [[self getMessage:indexPath] bareJidStr];
//    NSData *data = [[JIMCenter sharedInstance] getAvatar:jidStr];
//    return [PBFlatRoundedImageView contactImageViewWithImage:[UIImage imageWithData:data]];
    return nil;
}


#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma These are private methods.

-(XMPPMessageArchiving_Message_CoreDataObject *)getMessage:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.row];
}


@end
