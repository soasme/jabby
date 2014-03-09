//
//  JAppDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#define HAVE_XMPP_SUBSPEC_ROSTER 1

#import <UIKit/UIKit.h>
#import "JIMCenter.h"


@interface JAppDelegate : UIResponder <UIApplicationDelegate> {
    BOOL isOpen;
    NSString *password;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) JIMCenter *imCenter;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end
