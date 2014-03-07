//
//  JAppDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPP.h"

@interface JAppDelegate : UIResponder <UIApplicationDelegate> {
    XMPPStream *xmppStream;
    BOOL isOpen;
    NSString *password;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) XMPPStream *xmppStream;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// XMPP delegation.
- (BOOL)connect;
- (void)disconnect;
- (void)setupStream;
- (void)goOnline;
- (void)goOffline;

@end
