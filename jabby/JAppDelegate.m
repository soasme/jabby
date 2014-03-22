//
//  JAppDelegate.m
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JAppDelegate.h"

#import "JMasterViewController.h"
#import "JLoginViewController.h"
#import "PBFlatSettings.h"

@implementation JAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize imCenter = _imCenter;
@synthesize localNotification = _localNotification;
@synthesize backgroundTask, backgroundTimer, didShowDisconnectionWarning;
@synthesize navigationController = _navigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        self.navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)self.navigationController.topViewController;
        UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
        JMasterViewController *controller = (JMasterViewController *)masterNavigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    } else {
        self.navigationController = (UINavigationController *)self.window.rootViewController;
        
        JMasterViewController *controller = (JMasterViewController *)self.navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        
        
    }
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor midnightBlueColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], NSForegroundColorAttributeName,
      [UIFont fontWithName:@"ArialMT" size:20.0], NSFontAttributeName,nil]];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor peterRiverColor]
                                  highlightedColor:[UIColor belizeHoleColor]
                                      cornerRadius:5];
    [[PBFlatSettings sharedInstance] setMainColor:[UIColor whiteColor]];

    
    // Setup stream before all operations.
    [self setupIMCenter];
    self.localNotification = [[UILocalNotification alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:nil object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAuthenticatedFailedOnApp:) name:@"Authenticate Failed" object:nil];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"Application entered background state.");
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);
    self.didShowDisconnectionWarning = NO;
    
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Background task expired");
            if (self.backgroundTimer)
            {
                [self.backgroundTimer invalidate];
                self.backgroundTimer = nil;
            }
            [application endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
            
            
        });
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
    });
}

- (void) timerUpdate:(NSTimer*)timer {
    if (![self.imCenter.xmppStream isConnected]) {
        NSLog(@"Try to reconnect");
        [self.imCenter connect];
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    
    NSLog(@"Timer update, background time left: %f", application.backgroundTimeRemaining);
    
    if ([application backgroundTimeRemaining] < 60 && !self.didShowDisconnectionWarning)
    {
//        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
//        if (localNotif) {
//            localNotif.alertBody = @"Jabby网络连接超时";
//            localNotif.alertAction = @"好的";
//            localNotif.soundName = UILocalNotificationDefaultSoundName;
//            [application presentLocalNotificationNow:localNotif];
//        }
        NSLog(@"Will expiration");
        self.didShowDisconnectionWarning = YES;
    }
    if ([application backgroundTimeRemaining] < 10)
    {
        // Clean up here
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
        
//        OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
//        for(id key in protocolManager.protocolManagers)
//        {
//            id <OTRProtocol> protocol = [protocolManager.protocolManagers objectForKey:key];
//            [protocol disconnect];
//        }
//        [OTRManagedAccount resetAccountsConnectionStatus];
        
        
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSLog(@"Application became active");
    if (self.backgroundTimer)
    {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    if (self.backgroundTask != UIBackgroundTaskInvalid)
    {
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification*)notification{

//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"LocalNotification" message:notification.alertBody delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//    [alert show];
    
//    NSDictionary* dic = [[NSDictionary alloc]init];
//    //这里可以接受到本地通知中心发送的消息
//    dic = notification.userInfo;
//    NSLog(@"user info = %@",[dic objectForKey:@"key"]);
    
    // 图标上的数字减1
//    application.applicationIconBadgeNumber -= 1;
}


#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"jabby" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"jabby.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)setupIMCenter
{
    self.imCenter = [JIMCenter sharedInstance];
    self.imCenter.messageDelegate = self;
    isConnected = [self.imCenter connect];
    [self.imCenter loadCachedFriendList];
    return YES;
}

#pragma mark - JMessageDelegate
-(void)onReceivedMessage:(XMPPMessage *)message from:(id)user
{
    
}

- (void)sendNotification:(NSString *)text withUserInfo:(NSDictionary *)userInfo
{
    self.localNotification.applicationIconBadgeNumber = 1;
    self.localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    self.localNotification.timeZone = [NSTimeZone defaultTimeZone];
    self.localNotification.soundName = @"messageReceived.aiff";
    self.localNotification.repeatInterval = 0;
    
    
    self.localNotification.alertBody = text;
    self.localNotification.userInfo = userInfo;
    
    UIApplication *app=[UIApplication sharedApplication];
    [app presentLocalNotificationNow:self.localNotification];
}

- (FUIAlertView *)alert:(NSString *)message andTitle:(NSString *)title
{
    FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:nil cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil, nil];
    alertView.titleLabel.textColor = [UIColor cloudsColor];
    alertView.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    alertView.messageLabel.textColor = [UIColor cloudsColor];
    alertView.messageLabel.font = [UIFont flatFontOfSize:14];
    alertView.backgroundOverlay.backgroundColor = [[UIColor cloudsColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor midnightBlueColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor asbestosColor];
    alertView.defaultButtonFont = [UIFont boldFlatFontOfSize:16];
    alertView.defaultButtonTitleColor = [UIColor asbestosColor];
    [alertView show];
    return alertView;
}

- (BOOL)isConnected
{
    return isConnected;
}

- (void)didAuthenticatedFailedOnApp:(NSNotification *)notification
{
    [[JIMCenter sharedInstance].xmppReconnect stop];
    NSLog(@"%@", self.navigationController);
    [self.navigationController performSegueWithIdentifier:@"NavGoToLogin" sender:self];
    
}

- (void)log:(NSNotification *)notification
{
    //NSLog(@"Notification: %@", notification.name);
}
@end

