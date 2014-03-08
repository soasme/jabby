//
//  JAppDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#define HAVE_XMPP_SUBSPEC_ROSTER 1

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"
#import "XMPPRosterCoreDataStorage.h"
#import "JFriendListDelegate.h"
#import "XMPPvCardAvatarModule.h"
#import "JMessageDelegate.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPvCardTemp.h"
//#import "XMPPCapabilities.h"



@interface JAppDelegate : UIResponder <UIApplicationDelegate> {
    BOOL isOpen;
    NSString *password;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) XMPPStream *xmppStream;

@property (strong, nonatomic) XMPPRoster *xmppRoster;
@property (strong, nonatomic) XMPPRosterCoreDataStorage *xmppRosterStorage;

@property (strong, nonatomic) id<XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage> xmppvCardStorage;
@property (strong, nonatomic) XMPPvCardAvatarModule * xmppvCardAvatarModule;
@property (strong, nonatomic) XMPPvCardTempModule * xmppvCardTempModule;

//@property (strong, nonatomic) XMPPCapabilities * xmppCapabilities;
//@property (strong, nonatomic) id<XMPPCapabilitiesStorage> xmppCapabilitiesStorage;

@property (strong, nonatomic) id<JFriendListDelegate> friendListDelegate;
@property (strong, nonatomic) id<JMessageDelegate> messageDelegate;




- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// XMPP delegation.
- (BOOL)connect;
- (void)disconnect;
- (void)setupStream;
- (void)goOnline;
- (void)goOffline;

@end
