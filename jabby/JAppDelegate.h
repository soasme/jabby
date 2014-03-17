//
//  JAppDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#define HAVE_XMPP_SUBSPEC_ROSTER 1
#define DEBUG 1
#define XMPP_LOGGING_ENABLED 1


#import <UIKit/UIKit.h>
#import "JIMCenter.h"
#import "FUIAlertView.h"


@interface JAppDelegate : UIResponder <UIApplicationDelegate, JMessageDelegate> {
    BOOL isOpen;
    NSString *password;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) UILocalNotification *localNotification;

@property (strong, nonatomic) JIMCenter *imCenter;

@property (nonatomic, retain) NSTimer *backgroundTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) BOOL didShowDisconnectionWarning;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)sendNotification:(NSString *)text withUserInfo:(NSDictionary *)userInfo;
- (FUIAlertView *)alert:(NSString *)message andTitle:(NSString *)title;

@end
