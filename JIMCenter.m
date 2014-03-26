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
@synthesize sessions = _sessions;

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
        self.sessions = [NSMutableOrderedSet orderedSet];
    }
    return self;
}



- (BOOL)connect {
    [[self notiCenter] postNotificationName:@"Ready to connect" object:nil];
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
    return [self fetchMessage:jidStr recordNumber:20 page:0];
}

- (NSMutableArray *)fetchLastMessage:(NSString *)jidStr
{
    return [self fetchMessage:jidStr recordNumber:1 page:0];
}

- (NSMutableArray *)fetchMuchMoreMessage:(NSString *)jidStr page:(NSUInteger)page
{
    return [self fetchMessage:jidStr recordNumber:20 page:page];
}


- (NSMutableArray *)fetchMessage:(NSString *)jidStr recordNumber:(int)count page:(int)page
{
    NSManagedObjectContext *moc = [self.messageStorage mainThreadManagedObjectContext];
    NSEntityDescription *messageEntity = [self.messageStorage messageEntity:moc];
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr == %@ && body != nil", jidStr];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    fetchRequest.entity = messageEntity;
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.fetchLimit = count;
    fetchRequest.fetchOffset = page * 20;
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *meses = [moc executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *messages = [NSMutableArray array];
    for (id message in [[meses reverseObjectEnumerator] allObjects]) {
        JMessage *jMessage = [[JMessage alloc] initWithCoreData:message];
        [messages addObject:jMessage];
    }
    
    return messages;
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

- (UIImage *)getAvatarImage:(NSString *)jidStr
{
    NSData *avatarData = [self getAvatar:jidStr];
    UIImage *avatar;
    if (avatarData) {
        avatar = [UIImage imageWithData:avatarData];
    } else {
        avatar = [UIImage imageNamed:@"default_avatar.png"];
    }
    return avatar;
}

- (NSString *)getDisplayName:(NSString *)jidStr
{
    XMPPUserCoreDataStorageObject *u =[self getUserObjectByJidStr:jidStr];
    NSString *name = [u nickname];
    if (name) {
        return name;
    }
    name = [u displayName];
    if (name) {
        return name;
    }

    for (NSDictionary *people in self.onlineFriends) {
        if ([[people valueForKey:@"jid"] isEqualToString:jidStr]) {
            return [people valueForKey:@"name"];
        }
    }
    for (NSDictionary *people in self.offlineFriends) {
        if ([[people valueForKey:@"jid"] isEqualToString:jidStr]) {
            return [people valueForKey:@"name"];
        }
    }
    return @"";
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
    [[self notiCenter] postNotificationName:@"Lost Connection" object:nil];
    [self.xmppReconnect manualStart];
}



- (BOOL)connectedToNetwork:(SCNetworkConnectionFlags)connectionFlags{
    BOOL isReachable = connectionFlags & kSCNetworkFlagsReachable;
    BOOL needsConnection = connectionFlags & kSCNetworkFlagsConnectionRequired;
    return (isReachable && !needsConnection) ? YES : NO;
}

- (NSString *)friendCachedPath {
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"friend_cached.plist"];
}

- (void)cacheFriendList
{
    NSMutableArray *friendList = [NSMutableArray array];
    friendList[0] = [NSMutableArray arrayWithArray:self.onlineFriends];
    friendList[1] = [NSMutableArray arrayWithArray:self.offlineFriends];
    [friendList writeToFile:[self friendCachedPath] atomically:YES];
}

- (void)loadCachedFriendList
{
    NSMutableArray *friendList = [NSMutableArray arrayWithContentsOfFile:[self friendCachedPath]];
    self.onlineFriends = friendList[0];
    self.offlineFriends = friendList[1];
}

- (void)activeSession:(NSString *)jidStr
{
    [self.sessions addObject:jidStr];
}

- (void)logout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"UID"];
    [defaults removeObjectForKey:@"PASS"];
    [defaults synchronize];
    [self disconnect];
    [self.xmppReconnect stop];
    [self.onlineFriends removeAllObjects];
    [self.offlineFriends removeAllObjects];
    [self cacheFriendList];
}

- (BOOL)isLoggedOut
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return ![defaults valueForKey:@"UID"];
}
@end
