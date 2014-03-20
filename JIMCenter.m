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
@synthesize reconnectDelegate = _reconnectDelegate;
@synthesize xmppReconnect = _xmppReconnect;
@synthesize messageStorage = _messageStorage;

@synthesize onlineFriends = _onlineFriends;
@synthesize offlineFriends = _offlineFriends;

static JIMCenter *sharedIMCenterInstance = nil;
+ (JIMCenter *)sharedInstance
{
    @synchronized(self) {
        if (sharedIMCenterInstance == nil) {
            sharedIMCenterInstance = [[self alloc] initWithFriends];
        }
    }
    return sharedIMCenterInstance;
}

- (NSNotificationCenter *)notiCenter
{
    return [NSNotificationCenter defaultCenter];
}






- (id)initWithFriends
{
    if (self = [super init]) {
        [self setupStream];
        self.onlineFriends = [NSMutableArray array];
        self.offlineFriends = [NSMutableArray array];
    }
    return self;
}



- (BOOL)connect {
    self.xmppStream.myJID = [XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"UID"]];
    NSError *error = nil;
    if (![self.xmppStream connectWithTimeout: 2 error:&error]) {
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
    
    self.xmppRosterStorage = [XMPPRosterCoreDataStorage sharedInstance];
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
    self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    [self.xmppRoster activate:self.xmppStream];
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
    self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
    [self.xmppvCardTempModule activate:self.xmppStream];
    [self.xmppvCardAvatarModule activate:self.xmppStream];
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    self.xmppReconnect.autoReconnect = YES;
    self.xmppReconnect.reconnectDelay = 3;
    self.xmppReconnect.reconnectTimerInterval = 3;
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.messageStorage = (JMessageArchivingCoreDataStorage *)[XMPPMessageArchivingCoreDataStorage sharedInstance];
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
    [self auth];
}
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [[self notiCenter] postNotificationName:@"Authenticate Success" object:nil];
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
    [[self notiCenter] postNotificationName:@"Authenticate Failed" object:error];
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    if ([message isChatMessageWithBody]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"outgoing",@"kind", nil];
        NSNotification *notification = [NSNotification notificationWithName:@"Chat Message Outgoing"
                                                                     object:message
                                                                   userInfo:userInfo];
        [[self notiCenter] postNotification:notification];
    }
}
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    if ([message isChatMessageWithBody]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"incoming",@"kind", nil];
        NSNotification *notification = [NSNotification notificationWithName:@"Chat Message Incoming"
                                                                     object:message
                                                                   userInfo:userInfo];
        [[self notiCenter] postNotification:notification];
    }
}

- (void)auth
{
    NSError *error = nil;
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    BOOL result = [self.xmppStream authenticateWithPassword:password error:&error];
    if (result == NO) {
        [[self notiCenter] postNotificationName:@"Authendicate Failed" object:error];
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
}

- (void)markFriendOnline:(NSString *)jid
{
    NSDictionary *he = [NSDictionary dictionary];
    for (NSDictionary *people in [NSArray arrayWithArray:self.offlineFriends]) {
        if ([jid isEqualToString:[people valueForKey:@"jid"]]) {
            he = [NSDictionary dictionaryWithDictionary:people];
            [self.offlineFriends removeObject:people];
        }
    }
    BOOL isInOnline = NO;
    for (NSDictionary *people in self.onlineFriends) {
        if ([jid isEqualToString:[people valueForKey:@"jid"]]) {
            isInOnline = YES;
            break;
        }
    }
    if (!isInOnline && [he valueForKey:@"name"]) {
        [self.onlineFriends addObject:he];
    }
}
- (void)markFriendOffline:(NSString *)jid
{
    NSDictionary *he = [NSDictionary dictionary];
    for (NSDictionary *people in [NSArray arrayWithArray:self.onlineFriends]) {
        if ([jid isEqualToString:[people valueForKey:@"jid"]]) {
            he = [NSDictionary dictionaryWithDictionary:people];
            [self.onlineFriends removeObject:people];
        }
    }
    BOOL isInOffline = NO;
    for (NSDictionary *people in self.offlineFriends) {
        if ([jid isEqualToString:[people valueForKey:@"jid"]]) {
            isInOffline = YES;
            return;
        }
    }
    if (!isInOffline && [he valueForKey:@"name"]) {
        [self.offlineFriends addObject:he];
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSString *presenceType = [presence type];
    NSString *userId = [[sender myJID] user];
    NSString *presenceFromUser = [[presence from] bare];
    
    if (![presenceFromUser isEqualToString:userId]) {
        
        if ([presenceType isEqualToString:@"available"]) {
            [self markFriendOnline:presenceFromUser];
            NSLog(@"Presence: %@", presenceFromUser);
            NSNotification *notification = [NSNotification notificationWithName:@"Presence" object:presence];
            [[self notiCenter] postNotification:notification];
            
        } else if ([presenceType isEqualToString:@"unavailable"]) {
            [self markFriendOffline:presenceFromUser];
            NSNotification *notification = [NSNotification notificationWithName:@"Absence" object:presence];
            [[self notiCenter] postNotification:notification];
        }
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    if ([@"result" isEqualToString:iq.type])
    {
        NSMutableArray *friends = [NSMutableArray array];
        NSArray *children = [iq.childElement children];
        for (NSXMLElement *item in children)
        {
            NSString *jid = [item attributeStringValueForName:@"jid"];
            NSString *name = [item attributeStringValueForName:@"name"];
            if (!jid || !name) {
                continue;
            }
            // and subscription?
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:jid,@"jid",name,@"name", nil];
            [friends addObject:dict];
        }
        for (NSDictionary *people in friends) {
            NSString *jid = [people valueForKey:@"jid"];
            if ([self isFriendOnline:jid] && ![self.onlineFriends containsObject:people]) {
                [self.onlineFriends addObject:people];
            } else if (![self.offlineFriends containsObject:people]) {
                [self.offlineFriends addObject:people];
            }
        }
        [[self notiCenter] postNotificationName:@"IQ Received" object:nil];
    }
    
    
    
    return YES;
}

- (NSMutableArray *)fetchLatestMessage:(NSString *)jidStr
{
    NSManagedObjectContext *moc = [self.messageStorage mainThreadManagedObjectContext];
    NSEntityDescription *messageEntity = [self.messageStorage messageEntity:moc];
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@", jidStr];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    fetchRequest.entity = messageEntity;
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.fetchLimit = 20;
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *meses = [moc executeFetchRequest:fetchRequest error:&error];
    
    return [NSMutableArray arrayWithArray:[[meses reverseObjectEnumerator] allObjects]];
}

- (XMPPUserCoreDataStorageObject *)getUserObject:(XMPPJID *)jid
{
    return [self.xmppRosterStorage userForJID:jid
                                   xmppStream:self.xmppStream
                                   managedObjectContext:[self.xmppRosterStorage mainThreadManagedObjectContext]];
}

- (XMPPUserCoreDataStorageObject *)getUserObjectByJidStr:(NSString *)jidStr
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    return [self getUserObject:jid];
}

- (BOOL)isFriendOnline:(NSString *)jidStr
{
    XMPPUserCoreDataStorageObject *u =[self getUserObjectByJidStr:jidStr];
    return [u isOnline];
}

- (NSData *)getAvatar:(NSString *)jidStr
{
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    return [self.xmppvCardAvatarModule photoDataForJID:jid];
}

#pragma mark - XMPPReconnectDelegate
- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkConnectionFlags)connectionFlags {
    NSLog(@"didDetectAccidentalDisconnect %@ %d", sender, connectionFlags);
}
- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkConnectionFlags)connectionFlags {
    NSLog(@" shouldAttemptAutoReconnect %@ %d %d", sender, connectionFlags, [self connectedToNetwork:connectionFlags]);
    return YES;
}
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"disconnect");
//    [self.xmppReconnect manualStart];
}



- (BOOL)connectedToNetwork:(SCNetworkConnectionFlags)connectionFlags{
    BOOL isReachable = connectionFlags & kSCNetworkFlagsReachable;
    BOOL needsConnection = connectionFlags & kSCNetworkFlagsConnectionRequired;
    return (isReachable && !needsConnection) ? YES : NO;
}

@end
