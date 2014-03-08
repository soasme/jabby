//
//  JDetailViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

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

- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream
{
    return [[self appDelegate] xmppStream];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{


}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    [self appDelegate].messageDelegate = self;
    
    messages = [NSMutableArray array];
    
    self.delegate = self;
    self.dataSource = self;
    
    self.title = @"与 ... 聊天";
    
    self.messages = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
}

- (void)viewDidUnload
{
    [self setView:nil];
    [super viewDidUnload];
}

# pragma mark - JMessageDelegate

- (void)onReceivedMessage:(XMPPMessage *)message
{
    if ([message isMessageWithBody]) {
        //[messages addObject:message];
        [JSMessageSoundEffect playMessageReceivedSound];
        [self.timestamps addObject:[NSDate date]];
        [self.messages addObject:[NSDictionary dictionaryWithObject:[message body] forKey:@"Text"]];
        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];
        NSLog(@"%@", self.messages);
        

        
        
        
        
    } else {
        // active? pause? typing?
        // http://wiki.jabbercn.org/XEP-0085#.E5.AE.9A.E4.B9.89
    }
    
}


//# pragma mark - UITableViewDataSource
//-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
//    
//    return 1;
//}
//-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [messages count];
//}
//-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *identifier = @"msgCell";
//    XMPPMessage *message = [messages objectAtIndex:indexPath.row];
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//    if (cell == nil)
//    {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
//    }
//    
//    cell.textLabel.text = [message body];
//    cell.detailTextLabel.text = [[message from] user];
//    cell.accessoryType = UITableViewCellAccessoryNone;
//    
//    return cell;
//}

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
    [self.messages addObject:[NSDictionary dictionaryWithObject:text forKey:@"Text"]];
    
    [self.timestamps addObject:[NSDate date]];
    [JSMessageSoundEffect playMessageSentSound];
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    [mes addAttributeWithName:@"to" stringValue:@"1e6hri4nzpkx71vqdroamlu9u2@public.talk.google.com"];
    [mes addAttributeWithName:@"from" stringValue:[[self xmppStream].myJID full]];
    [body setStringValue:text];
    [mes addChild:body];
    [[self xmppStream] sendElement:mes];
    //[messages addObject:mes];
    
    
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
    return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleFlat;
}

- (JSBubbleMediaType)messageMediaTypeForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([[self.messages objectAtIndex:indexPath.row] objectForKey:@"Text"]){
        return JSBubbleMediaTypeText;
    }else if ([[self.messages objectAtIndex:indexPath.row] objectForKey:@"Image"]){
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
    if([[self.messages objectAtIndex:indexPath.row] objectForKey:@"Text"]){
        return [[self.messages objectAtIndex:indexPath.row] objectForKey:@"Text"];
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
    if([[self.messages objectAtIndex:indexPath.row] objectForKey:@"Image"]){
        return [[self.messages objectAtIndex:indexPath.row] objectForKey:@"Image"];
    }
    return nil;
    
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
    self.willSendImage = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.messages addObject:[NSDictionary dictionaryWithObject:self.willSendImage forKey:@"Image"]];
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
