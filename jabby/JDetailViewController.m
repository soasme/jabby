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
    JSMessagesViewDelegate,
    JSMessagesViewDataSource,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
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
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    self.delegate = self;
    self.dataSource = self;
    

    self.title = [self hisName];
    
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


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    [[JIMCenter sharedInstance] sendMessage:text to:[self hisJidStr]];
    [JSMessageSoundEffect playMessageSentSound];
    [self finishSend];
    self.messages = [[JIMCenter sharedInstance] fetchLatestMessage:[self hisJidStr]];
    [self.tableView reloadData];
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
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)information
{
	NSLog(@"Chose image!  Details:  %@", information);
    
    self.willSendImage = [information objectForKey:UIImagePickerControllerEditedImage];
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
