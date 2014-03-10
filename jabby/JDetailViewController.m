//
//  JDetailViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//
// TODO
//* Save latest chat message
//* upload image
//* set the right title
//* get the right person
//* handle incoming and outgoing background

#import "JDetailViewController.h"

@interface JDetailViewController () <
    JMessageDelegate,
    JSMessagesViewDelegate,
    JSMessagesViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
>

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (strong, nonatomic) NSMutableArray *messages;
@property (nonatomic,strong) UIImage *willSendImage;

- (void)configureView;

@end



@implementation JDetailViewController

@synthesize table;
@synthesize messages;
@synthesize willSendImage;
@synthesize timestamps;
@synthesize card = _card;

- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem andCard:(id)card
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
    if (self.card != card) {
        self.card = card;
    }
        // Update the view.
    [self configureView];
    

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
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    [self appDelegate].imCenter.messageDelegate = self;
    
    messages = [NSMutableArray array];
    
    self.delegate = self;
    self.dataSource = self;
    
    //self.title = @"与 ... 聊天";
    //self.navigationController.navigationBar.topItem.title = @"返回";
    self.title = [NSString stringWithFormat:@"与 %@ 聊天", [self.card formattedName]];
    
    self.messages = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    //XMPPJID *myJID = [self appDelegate].imCenter.xmppStream.myJID;
    
    [self fetchLatestMessage];
    [self reloadToBottom];
    
}

- (void)fetchLatestMessage
{
    NSManagedObjectContext *moc = [[self appDelegate].imCenter.messageStorage mainThreadManagedObjectContext];
    NSEntityDescription *messageEntity = [[self appDelegate].imCenter.messageStorage messageEntity:moc];
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = messageEntity;
    fetchRequest.fetchBatchSize = 20;
    
    NSError *error = nil;
    NSArray *meses = [moc executeFetchRequest:fetchRequest error:&error];
    
    self.messages = [NSMutableArray arrayWithArray:meses];
}

- (void)viewDidUnload
{
    [self setView:nil];
    [super viewDidUnload];
}

# pragma mark - JMessageDelegate

- (void)onReceivedMessage:(XMPPMessage *)message from:(id)user
{
    if ([message isMessageWithBody]) {
        //[messages addObject:message];
        [JSMessageSoundEffect playMessageReceivedSound];
//        [self.timestamps addObject:[NSDate date]];
//        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[message body],@"Text",[user displayName],@"Sender", nil];
//        [self.messages addObject:dict];
        [self reloadToBottom];
    } else {
        // active? pause? typing?
        // http://wiki.jabbercn.org/XEP-0085#.E5.AE.9A.E4.B9.89
    }
    
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


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    [mes addAttributeWithName:@"to" stringValue:[[_detailItem from] bare]];
    [mes addAttributeWithName:@"from" stringValue:[[self appDelegate].imCenter.xmppStream.myJID full]];
    [body setStringValue:text];
    [mes addChild:body];
    [[self appDelegate].imCenter.xmppStream sendElement:mes];
    
    //NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:text,@"Text",@"self",@"Sender", nil];
    //[self.messages addObject:dict];
    //[self.timestamps addObject:[NSDate date]];
    
    [[self appDelegate].imCenter.messageStorage archiveMessage:[XMPPMessage messageFromElement:mes]
                                                      outgoing:YES xmppStream:[self appDelegate].imCenter.xmppStream];
    [self fetchLatestMessage];
    [self.tableView reloadData];
    [JSMessageSoundEffect playMessageSentSound];
    
    
    [self finishSend];
}

- (void)cameraPressed:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.messages objectAtIndex:indexPath.row] isOutgoing]) {
        return JSBubbleMessageTypeOutgoing;
    } else {
        return JSBubbleMessageTypeIncoming;
    }
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleFlat;
}

- (JSBubbleMediaType)messageMediaTypeForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([[self.messages objectAtIndex:indexPath.row] body]){
        return JSBubbleMediaTypeText;
    } else {
        return JSBubbleMediaTypeImage;
    }
    
    return -1;
}

- (UIButton *)sendButton
{
    return [UIButton defaultSendButton];
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    /*
     JSMessagesViewTimestampPolicyAll = 0,
     JSMessagesViewTimestampPolicyAlternating,
     JSMessagesViewTimestampPolicyEveryThree,
     JSMessagesViewTimestampPolicyEveryFive,
     JSMessagesViewTimestampPolicyCustom
     */
    return JSMessagesViewTimestampPolicyCustom;
}



- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    /*
     JSMessagesViewAvatarPolicyIncomingOnly = 0,
     JSMessagesViewAvatarPolicyBoth,
     JSMessagesViewAvatarPolicyNone
     */
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle
{
    /*
     JSAvatarStyleCircle = 0,
     JSAvatarStyleSquare,
     JSAvatarStyleNone
     */
    return JSAvatarStyleNone;
}

- (JSInputBarStyle)inputBarStyle
{
    /*
     JSInputBarStyleDefault,
     JSInputBarStyleFlat
     
     */
    return JSInputBarStyleFlat;
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([[self.messages objectAtIndex:indexPath.row] body]){
        return [[self.messages objectAtIndex:indexPath.row] body];
    }
    return nil;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    return [self.timestamps objectAtIndex:indexPath.row];
    return nil;
}

- (UIImage *)avatarImageForIncomingMessage
{
    return [UIImage imageNamed:@"demo-avatar-jobs"];
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [UIImage imageNamed:@"demo-avatar-woz"];
}

- (id)dataForRowAtIndexPath:(NSIndexPath *)indexPath{
//    if([[self.messages objectAtIndex:indexPath.row] objectForKey:@"Image"]){
//        return [[self.messages objectAtIndex:indexPath.row] objectForKey:@"Image"];
//    }
    return nil;
    
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
    self.willSendImage = [info objectForKey:UIImagePickerControllerEditedImage];
    NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:self.willSendImage,@"Image",@"self",@"Sender", nil];
    [self.messages addObject:message];
    [self.timestamps addObject:[NSDate date]];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
    
	
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
