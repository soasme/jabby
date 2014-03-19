//
//  JIMCenter.h
//  jabby
//
//  Created by 林 炬 on 14-3-8.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPMessageArchiving.h"
#import "XMPPvCardTemp.h"
#import "XMPPReconnect.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPReconnect.h"

#import "JFriendListDelegate.h"
#import "JMessageDelegate.h"
#import "JMessageArchivingCoreDataStorage.h"

@interface JIMCenter : NSObject

@property (strong, nonatomic) id<JFriendListDelegate> friendListDelegate;
@property (strong, nonatomic) id<JMessageDelegate> messageDelegate;
@property (strong, nonatomic) id<XMPPReconnectDelegate> reconnectDelegate;

@property (strong, nonatomic) XMPPStream *xmppStream;

@property (strong, nonatomic) XMPPRoster *xmppRoster;
@property (strong, nonatomic) XMPPRosterCoreDataStorage *xmppRosterStorage;

@property (strong, nonatomic) id<XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage> xmppvCardStorage;
@property (strong, nonatomic) XMPPvCardAvatarModule * xmppvCardAvatarModule;
@property (strong, nonatomic) XMPPvCardTempModule * xmppvCardTempModule;

@property (strong, nonatomic) XMPPReconnect * xmppReconnect;

@property (strong, nonatomic) JMessageArchivingCoreDataStorage *messageStorage;

@property (strong, nonatomic) NSMutableArray *onlineFriends;
@property (strong, nonatomic) NSMutableArray *offlineFriends;

+ (JIMCenter *)sharedInstance;
- (void)auth;
- (id)initWithFriends;
- (BOOL)connect;
- (BOOL)disconnect;
- (void)setupStream;
- (void)goOnline;
- (void)goOffline;
- (void)sendMessage:(NSString *)text to:(NSString *)bareJid;
- (NSMutableArray *)fetchLatestMessage:(NSString *)jidStr;
- (XMPPUserCoreDataStorageObject *)getUserObject:(XMPPJID *)jid;
- (XMPPUserCoreDataStorageObject *)getUserObjectByJidStr:(NSString *)jidStr;
- (BOOL)isFriendOnline:(NSString *)jidStr;
- (NSData *)getAvatar:(NSString *)jidStr;
- (BOOL)connectedToNetwork:(SCNetworkConnectionFlags)connectionFlags;

@end
