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
#import "XMPPvCardTemp.h"
#import "XMPPReconnect.h"

#import "JFriendListDelegate.h"
#import "JMessageDelegate.h"

@interface JIMCenter : NSObject

@property (strong, nonatomic) id<JFriendListDelegate> friendListDelegate;
@property (strong, nonatomic) id<JMessageDelegate> messageDelegate;

@property (strong, nonatomic) XMPPStream *xmppStream;

@property (strong, nonatomic) XMPPRoster *xmppRoster;
@property (strong, nonatomic) XMPPRosterCoreDataStorage *xmppRosterStorage;

@property (strong, nonatomic) id<XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage> xmppvCardStorage;
@property (strong, nonatomic) XMPPvCardAvatarModule * xmppvCardAvatarModule;
@property (strong, nonatomic) XMPPvCardTempModule * xmppvCardTempModule;

@property (strong, nonatomic) XMPPReconnect * xmppReconnect;

- (BOOL)connect;
- (BOOL)disconnect;
- (void)setupStream;
- (void)goOnline;
- (void)goOffline;

@end
