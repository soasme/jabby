//
//  JDetailViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JDetailViewController.h"

@interface JDetailViewController ()
{
    //NSMutableArray *messages;
    IBOutlet UITableView *table;
}


@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (strong, nonatomic) NSMutableArray *messages;

- (void)configureView;

@end



@implementation JDetailViewController

@synthesize table;
@synthesize messages;

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

    self.table.delegate = self;
    self.table.dataSource = self;
    
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
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        
        NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
        [mes addAttributeWithName:@"type" stringValue:@"chat"];
        [mes addAttributeWithName:@"to" stringValue:[[message from] bare]];
        [mes addAttributeWithName:@"from" stringValue:[[self xmppStream].myJID full]];
        [body setStringValue:[message body]];
        [mes addChild:body];
        [[self xmppStream] sendElement:mes];
        
        [messages addObject:message];
        [messages addObject:mes];
        
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

@end
