//
//  JIMCenter.m
//  jabby
//
//  Created by 林 炬 on 14-3-8.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JIMCenter.h"

@implementation JIMCenter

@synthesize xmppStream = _xmppStream;
@synthesize xmppRoster = _xmppRoster;
@synthesize xmppRosterStorage = _xmppRosterStorage;
@synthesize xmppvCardAvatarModule = _xmppvCardAvatarModule;
@synthesize xmppvCardStorage = _xmppvCardStorage;
@synthesize xmppvCardTempModule = _xmppvCardTempModule;
@synthesize messageDelegate = _messageDelegate;
@synthesize friendListDelegate = _friendListDelegate;
@synthesize xmppReconnect = _xmppReconnect;
@synthesize messageStorage = _messageStorage;

- (id)initWithXMPP:(XMPPStream *)stream
{
    if (self = [super init]) {
        
    }
    return self;
}

- (BOOL)connect {
    self.xmppStream.myJID = [XMPPJID jidWithString:@"soasme.insecure@gmail.com"];
    NSError *error = nil;
    if (![self.xmppStream connectWithTimeout: 2 error:&error]) {
        NSLog(@"Ooops, forgot something");
        return FALSE;
    } else {
        NSLog(@"Success Connect to gtalk");
        return TRUE;
    }
}

- (BOOL)disconnect {
    [self goOffline];
    [self.xmppStream disconnect];
    return YES;
}

- (void)setupStream {
    self.xmppStream = [[XMPPStream alloc] init];
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.xmppStream.enableBackgroundingOnSocket = YES;
    
    self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
    self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    [self.xmppRoster activate:self.xmppStream];
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
    self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
    [self.xmppvCardTempModule activate:self.xmppStream];
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    self.xmppReconnect.autoReconnect = YES;
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    XMPPMessageArchiving *messageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:self.messageStorage];
    [messageArchiving setClientSideMessageArchivingOnly:YES];
    [messageArchiving activate:self.xmppStream];
    [messageArchiving addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void)goOnline {
    XMPPPresence *presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}
- (void)goOffline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [self.xmppStream sendElement:presence];
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSError *error = nil;
    if (![self.xmppStream authenticateWithPassword:@"soasme.test" error:&error]) {
        NSLog(@"Auth fail. %@ %@", error, [error userInfo]);
    } else {
        NSLog(@"Auth success");
    }
}
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self goOnline];
}
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    // delegate to messageDelegate
    
    XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[message from]
                                                              xmppStream:self.xmppStream
                                                    managedObjectContext:[self.xmppRosterStorage mainThreadManagedObjectContext]];
    if ([message isMessageWithBody]) {
//        [self.messageStorage archiveMessage:message outgoing:NO xmppStream:self.xmppStream];
        [self.messageDelegate onReceivedMessage:message from:user];
        NSLog(@"did receive message %@", message);
    }
    
}

- (void)sendMessage:(NSString *)text to:(NSString *)bareJid {
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    [mes addAttributeWithName:@"to" stringValue:bareJid];
    [mes addAttributeWithName:@"from" stringValue:[self.xmppStream.myJID full]];
    [body setStringValue:text];
    [mes addChild:body];
    [self.xmppStream sendElement:mes];
//    [self.messageStorage archiveMessage:[XMPPMessage messageFromElement:mes]
//                               outgoing:YES xmppStream:self.xmppStream];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSString *presenceType = [presence type];
    NSString *userId = [[sender myJID] user];
    NSString *presenceFromUser = [[presence from] user];
    if (![presenceFromUser isEqualToString:userId]) {
        if ([presenceType isEqualToString:@"available"]) {
            [self.friendListDelegate onPresence:presence];
        } else if ([presenceType isEqualToString:@"unavailable"]) {
            [self.friendListDelegate onAbsence:presence];
        }
    }
}




@end
